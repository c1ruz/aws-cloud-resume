# ☁️ Cloud Resume Challenge – AWS Edition

This is my personal **Cloud Resume** built entirely on AWS infrastructure as code.  
The resume is a static website hosted on **Amazon S3**, with a **visitor counter** powered by **AWS Lambda**, **DynamoDB**, and **API Gateway**.  
The entire stack is provisioned using **Terraform** and managed via **Terraform Cloud** with **GitHub Actions** for CI/CD. 
A **Cloudflare distribution** provides a custom domain and HTTPS.


## 🧱 Architecture Overview

1. **S3 Bucket** – hosts the static `index.html` file and enables static website hosting.  
2. **Lambda Function** – updates and returns the visit count.  
3. **DynamoDB Table** – stores a single item `page_id = "homepage"` with an atomic `visit_count` counter.  
4. **API Gateway (HTTP API)** – exposes a `/test` endpoint (GET/POST) that triggers the Lambda.  
5. **Terraform** – provisions every component and enforces infrastructure immutability.  
6. **Terraform Cloud** – manages remote state and collaboration.

