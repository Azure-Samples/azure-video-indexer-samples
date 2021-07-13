    # Find the Dockerfile for mcr.microsoft.com/azure-functions/dotnet:3.0-dotnet3-core-tools at this URL
# https://github.com/Azure/azure-functions-docker/blob/master/host/3.0/buster/amd64/dotnet/dotnet-core-tools.Dockerfile
FROM mcr.microsoft.com/azure-functions/dotnet:3.0-dotnet3-core-tools

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Install system tools
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils nano unzip curl icu-devtools bash-completion jq

# Configure git prompt
ENV GIT_PROMPT_START='\033[1;36menrichmentpipeline-dc>\033[0m\033[0;33m\w\a\033[0m'

# Save command line history 
RUN echo "export HISTFILE=/root/commandhistory/.bash_history" >> "/root/.bashrc" \
    && echo "export PROMPT_COMMAND='history -a'" >> "/root/.bashrc" \
    && mkdir -p /root/commandhistory \
    && touch /root/commandhistory/.bash_history

RUN echo "source /usr/share/bash-completion/bash_completion" >> "/root/.bashrc"

# Install mdspell and linkcheck
RUN \
    apt-get install -y nodejs npm \
    && npm i markdown-spellcheck -g \
    && npm i markdown-link-check -g

# Git command prompt
RUN git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1 \
    && echo "if [ -f \"$HOME/.bash-git-prompt/gitprompt.sh\" ]; then GIT_PROMPT_ONLY_IN_REPO=1 && source $HOME/.bash-git-prompt/gitprompt.sh; fi" >> "/root/.bashrc"

# Install Powershell
RUN echo "alias powershell=pwsh" >> "/root/.bashrc"
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/microsoft.list \
    && apt-get update \
    && apt-get install -y powershell

# Install powershell unit testing framework, task runner and script analyser
RUN pwsh -c "Install-Module -Name Pester -RequiredVersion 4.6.0 -Force"
RUN pwsh -c "Install-Module -Name PSake -Force"
RUN pwsh -c "Install-Module -Name PSScriptAnalyzer -Force"
RUN pwsh -c "Install-Module -Name Az -AllowClobber -Force"

# Install Terraform
ARG TERRAFORM_VERSION=0.13.2
ARG TFLINT_VERSION=0.19.1
RUN \
    mkdir -p /tmp/docker-downloads \
    && curl -sSL -o /tmp/docker-downloads/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip /tmp/docker-downloads/terraform.zip \
    && mv terraform /usr/local/bin \
    && rm /tmp/docker-downloads/terraform.zip
RUN echo "alias tf=terraform" >> "/root/.bashrc"

# Install TFlint
RUN \
    curl -sSL -o /tmp/docker-downloads/tflint.zip https://github.com/wata727/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
    && unzip /tmp/docker-downloads/tflint.zip \
    && mv tflint /usr/local/bin \
    && rm /tmp/docker-downloads/tflint.zip

# Install dotnet format
RUN dotnet tool install -g dotnet-format
ENV PATH="$PATH:/root/.dotnet/tools"