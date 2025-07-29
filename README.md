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

#### 1. The flask app has three endpoints. The first endpoint is "/gandalf" this shows an image of gandalf. When a user accesses this endpoint, an increment of 1 is added into a variable that will be used as a metric by Prometheus. http://4.232.114.218/gandalf

#### 2. The second endpoint "/colombo" shows the time in colombo standard time. Accessing it also adds and increment in a variable in the app for metrics. http://4.232.114.218/colombo

#### 3. The third endpoint shows the metrices themselves. In this app, the endpoint "/metrics" is primarity open for Prometheus to scrape metrics from this application and show them in the Prometheus UI. The prometheus server is installed in another cloud provider and another VM. http://4.232.114.218/metrics

The code can be found [here](https://github.com/samishafique786/observability-w-prometheus/blob/main/pyapp/app.py).

### AKS Cluster




## Infrastrucutre Provisioning

The application has been deployed in an AKS cluster in Microsoft Azure cloud - region: italy-north. The observability server has been deployed in the CSC Cloud in Finland - region: Kajaani, Finland. At first, the application 
