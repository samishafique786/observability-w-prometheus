# Gandalf-App with Prometheus Monitoring

## Introduction

This project is a simple Flask-based web application deployed on Azure Kubernetes Service and monitored using Prometheus. 

It includes:

 --  A basic Flask app with three endpoints  
 --  Prometheus metrics exposure  
 --  Kubernetes deployment with a LoadBalancer service  
 --  Prometheus server scraping the app for metrics

### 1. The flast app has three endpoints. The first endpoint is "/gandalf" this shows an image of gandalf. When a user accesses this endpoint, an increment of 1 is added into a variable that will be used as a metric by Prometheus.

### 2. The second endpoint "/colombo" shows the time in colombo standard time. Accessing it also adds and increment in a variable in the app for metrics.

### 3. The third endpoint shows the metrices themselves. In this app, the endpoint "/metrics" is primarity open for Prometheus to scrape metrics from this application and show them in the Prometheus UI. The prometheus server is installed in another cloud provider and another VM.

## Architectural Diagram

The following architechtural diagram explains the high level architecture of server structure. 

<img width="771" height="601" alt="image" src="https://github.com/user-attachments/assets/a93a9dc7-635d-4a6c-84da-c024ced16775" />

