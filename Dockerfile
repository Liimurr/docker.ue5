FROM mcr.microsoft.com/windows:20H2
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; Set-ExecutionPolicy Unrestricted;"]

ARG GITHUB_PRIVATE_KEY

# install pwsh
ENV PWSH_VERSION='7.4.2'
ENV PWSH_HOME="c:/pwsh/${PWSH_VERSION}"
RUN Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' 'PATH' \"$env:PATH;%PWSH_HOME%/bin\" -Type 'ExpandString'
RUN [System.Environment]::SetEnvironmentVariable('PWSH_HOME', "${env:PWSH_HOME}", 'Machine')
RUN Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v${env:PWSH_VERSION}/PowerShell-${env:PWSH_VERSION}-win-x64.zip -OutFile 'pwsh.zip'
RUN New-Item -ItemType Directory -Path $env:PWSH_HOME -Force
RUN tar -xvf pwsh.zip -C $env:PWSH_HOME
RUN Remove-Item -Path 'pwsh.zip' -Force

SHELL ["c:/pwsh/7.4.2/pwsh.exe", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# install git
ENV GIT_VERSION=2.45.0
ENV GIT_HOME=c:/git/${GIT_VERSION}
ENV GIT_SSH=c:/Windows/System32/OpenSSH/ssh.exe
RUN Set-ItemProperty \
  -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' \
  -Name 'PATH' \
  -Value \"${env:PATH};%GIT_HOME%/cmd\" \
  -Type 'ExpandString'
RUN [System.Environment]::SetEnvironmentVariable('GIT_HOME', "${env:GIT_HOME}", 'Machine')
RUN New-Item -ItemType Directory -Path ${env:GIT_HOME} -Force | Out-Null
RUN Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v${env:GIT_VERSION}.windows.1/MinGit-${env:GIT_VERSION}-64-bit.zip -OutFile 'git.zip'
RUN tar -xf git.zip -C ${env:GIT_HOME}
RUN Remove-Item -Path git.zip -Force

# add github private key
ARG GITHUB_PRIVATE_KEY
RUN mkdir -p $env:USERPROFILE/.ssh | Out-Null
RUN $env:GITHUB_PRIVATE_KEY | Out-File -Encoding utf8 -FilePath \"$env:USERPROFILE/.ssh/github\" -Force
RUN \
\"Host github.com`n\
  HostName github.com`n\
  IdentityFile `\"$env:USERPROFILE/.ssh/github`\"`n\
\" | Out-File -FilePath \"$env:USERPROFILE/.ssh/config\" -Append -Force
RUN icacls "${env:USERPROFILE}/.ssh/github" /grant "${env:USERNAME}:F"

# add github to known hosts
RUN  ssh-keyscan -t rsa github.com | Out-File -FilePath \"$env:USERPROFILE/.ssh/known_hosts\"

# install vs
ENV VS_VERSION='17'
ENV VS_YEAR='2022'
ENV VCVARS_HOME="C:/Program Files/Microsoft Visual Studio/${VS_YEAR}/Community/VC/Auxiliary/Build"
COPY ./docker/vscomponents.ps1 ./vscomponents.ps1
RUN Invoke-WebRequest -Uri  https://aka.ms/vs/${env:VS_VERSION}/release/vs_community.exe -OutFile 'vs_community.exe'
RUN . ./vscomponents.ps1; \
    $Args = @('--wait', '--passive', '--norestart', '--nocache'); \
    $Args += $VSComponents | ForEach { \"--add $_\" }; \
    Start-Process -Wait -FilePath 'vs_community.exe' -ArgumentList $Args;
RUN Remove-Item -Path 'vscomponents.ps1' -Force
RUN Remove-Item -Path 'vs_community.exe' -Force

ENV UE5_VERSION='5.4.1'
ENV UE5_HOME="c:/workspace/ue5/${UE5_VERSION}"
ENV UE5_TAG="${UE5_VERSION}-release"
CMD ["cmd", "/c", "ping", "-t", "localhost", ">", "NUL"]