FROM python:3.7.2

MAINTAINER Ben Duncan

RUN apt-get update \
  && apt-get install -y jq \
  && apt-get install -y apt-transport-https \
  && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
  && apt-get update \
  && apt-get install -y kubectl \
  && curl https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator -o /usr/local/bin/aws-iam-authenticator \
  && chmod 755 /usr/local/bin/aws-iam-authenticator \
  && apt-get clean \
  && pip install awscli \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash", "-c", "aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name $EKS_CLUSTER_NAME && aws sts get-caller-identity && kubectl patch deployment/$K8_DEPLOYMENT -p '{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"lastupdated\":\"'$K8_UPDATEDATE'\"}}}}}'"]
