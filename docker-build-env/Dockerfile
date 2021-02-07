FROM public.ecr.aws/lts/ubuntu:latest as downloader
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    wget

FROM downloader as tf_downloader
ARG tf_version=0.14.5
RUN curl -JLO "https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip"
RUN unzip terraform_${tf_version}_linux_amd64.zip

FROM downloader as aws_cli2_downloader
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip

FROM downloader AS golang_downloader
ARG GOLANG_VERSION=1.15.7
RUN curl -JL "https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" -o golang.tar.gz

#FROM aws/codebuild/amazonlinux2-x86_64-standard:3.0
#FROM public.ecr.aws/r3q7n1l4/codebuild/amazonlinux2-x86_64-standard:3.0
FROM public.ecr.aws/lts/ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    apt-utils \
    build-essential \
    curl \
    jq \
    unzip \
    wget
COPY --from=tf_downloader terraform /usr/bin/local/terraform
COPY --from=aws_cli2_downloader awscliv2.zip awscliv2.zip
RUN unzip awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip ./aws \
        /usr/local/aws-cli/v2/*/dist/aws_completer \
        /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/*/dist/awscli/examples
COPY --from=golang_downloader golang.tar.gz golang.tar.gz
RUN tar -C /usr/local -xzf golang.tar.gz && rm golang.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
RUN curl -sSL https://get.docker.com/ | sh && \
    usermod -a -G docker root && \
    docker --version

ADD dockerd-entrypoint.sh /dockerd-entrypoint.sh
ENTRYPOINT [ "/dockerd-entrypoint.sh" ]
CMD []