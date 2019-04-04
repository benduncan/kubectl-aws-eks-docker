# Automating builds on Kubernetes

Need to automate builds to be deployed to your Kubernetes nodes? Look no further!

This tutorial will outline how to automate builds from Bitbucket and trigger a deploy on your Kubernetes nodes.

Setup infrastructure includes:

- AWS EKS - Amazon's Kubernetes implementation. Avoid using Amazon ECR and further vendor lock-in, use Kubernetes and at least you can migrate out 'easier' in the future.
- ECR - Amazon's container registry service, where our builds are uploaded and tagged.
- Bitbucket - Using Bitbucket pipelines to handle building our image

Tools used:

- AWS CLI
- kubectl
- aws-iam-authenticator

To use the Docker image to update your Kubernetes nodes the following environment fields must be specified:

```
AWS_ACCESS_KEY_ID = Your AWS access key
AWS_DEFAULT_REGION = Region the Kubernetes cluster is located in, e.g ap-southeast-2
AWS_REGISTRY_URL = ECR registry (optional, method B)
AWS_SECRET_ACCESS_KEY = Your AWS secret key
EKS_CLUSTER_NAME = The unique EKS cluster name
K8_DEPLOYMENT = The Kubernetes deployment name
K8_CONTAINERNAME = The Kubernetes container name used by the deployment (optional, method B)
K8_UPDATEDATE = Date (EPOCH) used as a workaround to update the deployment (Method A)
```

Once defined run the following to auto-build and push the changes to Kubernetes:

```
docker run -it -e AWS_ACCESS_KEY_ID="XXX" -e AWS_DEFAULT_REGION="ap-southeast-2" -e AWS_REGISTRY_URL="XXX.dkr.ecr.ap-southeast-2.amazonaws.com/XXX" -e AWS_SECRET_ACCESS_KEY="XXX" -e EKS_CLUSTER_NAME="XXX" -e K8_DEPLOYMENT="XXX" -e K8_CONTAINERNAME="XXX" -e K8_UPDATEDATE="`date +'%s'`" kubectl-aws-eks
```

The Dockerfile will execute the following in order:

```
aws eks --region ${AWS_DEFAULT_REGION} update-kubeconfig --name $EKS_CLUSTER_NAME
```

Set the EKS region to use and create a ~/.kube/config file based on the cluster and token authentication (requires the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)

```
aws sts get-caller-identity
```

Will confirm the AWS authentication tokens are successful

```
kubectl patch deployment/$K8_DEPLOYMENT -p '{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"lastupdated\":\"'$K8_UPDATEDATE'\"}}}}}'"
```

Using the (Method A) approach, the running Kubernetes deployment is updated using a workaround by updating the `lastupdated` label with the current EPOCH.

## Bitbucket configuration

In the Bitbucket repository > Deployments > Settings, define each of the ENV fields above (AWS_ACCESS_KEY_ID, etc) - Make sure the AWS_SECRET_ACCESS_KEY is defined and check the _lock_ option checked, so the secret is stored encrypted.

Depending on your bitbucket pipeline setup, you may have different builds for staging, development and production. If so, Bitbucket supports unique ENV fields depending on the deployment. If building for multiple deployments you can define the K8_DEPLOYMENT with a unique Kubernetes deployment (e.g app-staging, app-production, app-dev)

## Troubleshooting

For the Kubernetes deployment definition confirm `imagePullPolicy: Always` attribute is set, otherwise the image will not be pulled from ECR and the deployment will remain the same.

```
app-deployment.yaml:
...
image: XXX.dkr.ecr.ap-southeast-2.amazonaws.com/XXX:staging
imagePullPolicy: Always
...
```

Method A

Method B

kubectl set image deployment/$K8_DEPLOYMENT $K8_CONTAINERNAME=\$AWS_REGISTRY_URL:staging
