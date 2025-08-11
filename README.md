# Gandalf-App with Prometheus Monitoring

## Introduction

This project is a simple Flask-based web application deployed on Azure Kubernetes Service and monitored using Prometheus. 

It includes:

 --  A basic Flask app with three endpoints  
 --  Prometheus metrics exposure  
 --  Kubernetes deployment with a LoadBalancer service  
 --  Prometheus server scraping the app for metrices
 

## Architectural Diagram

The following architechtural diagram explains the high level architecture of server structure. 

<img width="771" height="601" alt="image" src="https://github.com/user-attachments/assets/a93a9dc7-635d-4a6c-84da-c024ced16775" />

### Gandalf App

The first step is the gandalf app that is written in Python. The framework used is Flask because it is easy to use when dealing with small web applications. Since this application has three endpoints only, flask is good.

1. The flask app has three endpoints. The first endpoint is "/gandalf" this shows an image of gandalf. When a user accesses this endpoint, an increment of 1 is added into a variable that will be used as a metric by Prometheus. http://4.232.114.218/gandalf

2. The second endpoint "/colombo" shows the time in colombo standard time. Accessing it also adds and increment in a variable in the app for metrics. http://4.232.114.218/colombo

3. The third endpoint shows the metrices themselves. In this app, the endpoint "/metrics" is primarity open for Prometheus to scrape metrics from this application and show them in the Prometheus UI. The prometheus server is installed in another cloud provider and another VM. http://4.232.114.218/metrics

The code can be found [here](https://github.com/samishafique786/observability-w-prometheus/blob/main/pyapp/app.py). 

The application then has to be containerized, so that it can run in a pod in a Kubernetes cluster. To do that, a [Dockerfile](https://github.com/samishafique786/observability-w-prometheus/blob/main/pyapp/Dockerfile)has been created that runs the app and opens the port 80 for HTTP requests.

#### Gandalf Image and GitLab Container Registry

Now that the gandalf app is containerized, it needs to be uploaded to a container registry. In this case, the Gitlab container registry has been chosen because I have fimiliarity with it, and no diffuclut setup is required. In the terminal, run the following commands **in order** to build and push the image to the GitLab container registry.

```bash
docker login registry.gitlab.com -u samishafique786 -p <GITLAB_PERSONAL_ACCESS_TOKEN>
```
The personal access token is important and should be saved for later use when authenticating K8s with the container registry.
```bash
docker build -t registry.gitlab.com/csc-rahti-group/gandalf-project:v1 .
```
Give the path of your gitlab project, give a name, and a tag. 

Finally, push the image to the container registry:
```bash
docker push registry.gitlab.com/csc-rahti-group/gandalf-project:v1
```




### Azure Kubernetes Service

To run this application that we have containerized in a Kubernetes cluster, Azure Kubernetes Service has been chosen. The reason for this choice is that I have credits given to me by my university.

Since my Azure account is managed by the university, I have permissions to create recourses mostly in the EU regions of Azure. So, for provisioning the cluster, the Italy-north region has been selected. (This is important for later when the static IP provisioning takes place.) 

#### 1. Resource Group

Before creating any resource (VM, Storage, Clusters, IP addresses) in Azure, a resource group must be created. A resource group is ideally where all the resources about an application should be created. My Resource group is called** MyStudentRG** - this is where all the resources related to my cluster will be. 

#### 2. AKS Cluster Creation and Setting Up Things 

Using the same Azure  UI, a kubernetes cluster has been created in the Italy-north region. This is a managed Kuberenets cluster, which means that we as customers are billed only for the worker nodes. In our case, the minimum amount of working nodes is 1, but during the provisioning of the cluster, we have allowed autoscaling to scale the node pool to 20 nodes.

The cluster is named **gandalf-az-cluster**. After the creation of the cluster, we need to configure the CLI (local terminal) to run **az** and **kubectl** commands. The Azure CLI has been downloaded using the Microsoft Installed (MSI) and to configure the Azure account, the folllowing commands have been used. 

```bash
az login
```
This will open a web browser where you authenticate with the Azure account. 

```bash
az az account set --subscription <xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx>
```
Choose the correct subscription. My account has two subscriptions, one of them is given to me by the university with some credits I can use. 

```bash
az aks get-credentials --resource-group MyStudentRG --name gandalf-az-cluster --overwrite-existing
```
This will download the KubeConfig file - this authenticates the terminal with the K8s cluster, and now we can run kubectl commands.

Now, in order to pull the image for running in our cluster, the cluster needs to authenticate to the GitLab container registry. For that, Kubernetes uses **Secrets**. The GitLab container registry authentication token with at least read permissions should be saved as a secret in our cluster. So, let's create this secret. 

```bash
kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=registry.gitlab.com \
  --docker-username=samishafique786 \
  --docker-password=<your-personal-access-token-or-deploy-token> \
  --docker-email=samishafique786@gmail.com
```
This will create a secret in K8s cluster that can authenticate with the registry for pulling images.

Deploying the App

There were two ways of deploying the application. One via K8s commands and flags, the other way is using YAML files. YAML files are good because they can be version controlled. We chose a mixture of YAML and commands. The first file is deployment.yaml which contains the name of the application, type of kubernetes object which is deployment, number of replicas needed of the app, the port to expose, and the imagePullSecrets.  

Deployment.yaml

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: registry.gitlab.com/csc-rahti-group/gandalf-project:v1
        ports:
        - containerPort: 80
      imagePullSecrets:
      - name: gitlab-registry-secret
```
```bash
kubectl apply -f Deployment.yaml
```
This will create a deployment named my-app, and a pod will start running with the Gandlalf container image we uploaded to the container registry. Now, the port 80 is exposed, but K8s needs a **Service** for networing and to expose the application to the outside world, we will use a Service type of **LoadBalancer**. However, a simple loadbalancer service uses a dynamic IP to expose the application, but in our case, the application will be monitored via Prometheus, and for that, a static IP is needed so that Prometheus can keep monitoring. 

So, we now create a static IP in Azure using a service called Public IP addresses. Since there are restrictions as to region of cluster being Italy-north, AKS uses an address that should be in the same resource group, and the region as well. So, using the Azure CLI (az), lets create the IP. 

We do know our cluster name and RG name, but the nodeResourceGroup is unknown, so let find out. 
```bash
az aks show --name gandalf-az-cluster --resource-group MyStudentRG --query nodeResourceGroup -o tsv
```
After finding your nodeResourseGroup name, run this commands to finally create a static public IP.
```bash
az network public-ip create \
    --resource-group <node resource group name> \
    --name myAKSPublicIP \
    --sku Standard \
    --allocation-method static
```
Get the static public IP address value:
```bash
az network public-ip show --resource-group <node resource group name> --name myAKSPublicIP --query ipAddress --output tsv
```
Check the AKS cluster identity type (to determine permissions setup)
```bash
az aks show --name gandalf-az-cluster --resource-group MyStudentRG --query identity.type --output tsv
```
In my case, the role is systemAssigned, so, this role needs permissions as a Network Contributer, so that this role can patch the Public IP to our deployment, otherwise, the Service in K8s will be pending due to less permissions. 

After carefully reading the Official microsoft [documentation]([url](https://learn.microsoft.com/en-us/azure/aks/static-ip)) https://learn.microsoft.com/en-us/azure/aks/static-ip on this matter, the following command does that:
```bash
az role assignment create \
    --assignee ${CLIENT_ID} \
    --role "Network Contributor" \
    --scope ${RG_SCOPE}
```
The ENV variables should be first saved according to the said MS documentation. After running this command, we are set to expose our deployment (gandalf-app) on port 80 using the static IP we created by using a LoadBalancer service. Remember, the name of our static IP resource is MyAKSPublicIP, so we will be refering this name in our Service.yaml file.

```bash
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: MC_MyStudentRG_gandalf-az-cluster_italynorth
    service.beta.kubernetes.io/azure-pip-name: myAKSPublicIP
  name: azure-load-balancer
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: my-app
```
```bash
kubectl apply -f Service.yaml
```
This will expose the app using the static Ip of http://72.146.20.152/gandalf

## Infrastructure Provisioning

The application has been deployed in an AKS cluster in Microsoft Azure cloud - region: italy-north. The observability server has been deployed in the CSC Cloud in Finland - region: Kajaani, Finland. At first, the application 
