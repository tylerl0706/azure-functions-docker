ARG HOST_COMMIT=dev
ARG BUILD_NUMBER=00001
FROM microsoft/dotnet:2.1-sdk AS installer-env
ARG HOST_COMMIT
ARG BUILD_NUMBER

ENV PublishWithAspNetCoreTargetManifest false

RUN export ARG_BUILD_NUMBER=${BUILD_NUMBER} && \
    if [ $ARG_BUILD_NUMBER = dev ]; \
    then export SCRIPT_BUILD_NUMBER=00001; \
    else export SCRIPT_BUILD_NUMBER=$(echo $ARG_BUILD_NUMBER | cut -d'.' -f 3 | cut -d'-' -f 1); \
    fi && \
    echo "Build Number == $SCRIPT_BUILD_NUMBER" &&\
    wget https://github.com/Azure/azure-functions-host/archive/${HOST_COMMIT}.tar.gz && \
    tar xvzf ${HOST_COMMIT}.tar.gz && \
    cd azure-functions-host-* && \
    dotnet build /p:BuildNumber="$SCRIPT_BUILD_NUMBER" WebJobs.Script.sln && \
    dotnet publish /p:BuildNumber="$SCRIPT_BUILD_NUMBER"  src/WebJobs.Script.WebHost/WebJobs.Script.WebHost.csproj --output /azure-functions-host

# Runtime image
FROM microsoft/dotnet:2.1-aspnetcore-runtime

COPY --from=installer-env ["/azure-functions-host", "/azure-functions-host"]

ENV AzureWebJobsScriptRoot=/home/site/wwwroot
ENV HOME=/home
ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80

CMD ["dotnet", "/azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost.dll"]
