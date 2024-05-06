FROM mcr.microsoft.com/windows:20H2
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; Set-ExecutionPolicy Unrestricted;"]

# install git
ENV GIT_VERSION=2.45.0
ENV GIT_HOME=c:/git/${GIT_VERSION}
RUN New-Item -ItemType Directory -Path ${env:GIT_HOME} -Force | Out-Null
RUN Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v${env:GIT_VERSION}.windows.1/MinGit-${env:GIT_VERSION}-64-bit.zip -OutFile 'git.zip'
RUN tar -xf git.zip -C ${env:GIT_HOME} --strip-components 1
RUN Remove-Item -Path git.zip -Force