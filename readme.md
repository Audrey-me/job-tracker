# Deployment and Testing Guide

## Introduction
This guide provides step-by-step instructions to deploy your Terraform configuration, provision AWS services, and test your API endpoints.

## Prerequisites
- Git installed on your local machine.
- Terraform installed on your local machine.
- AWS CLI installed and configured with necessary credentials.

## Steps to Deploy and Test API Endpoints

### 1. Clone the Repository
Clone the repository and navigate to the project directory.
```sh
git clone <repository_url>
cd <repository_directory>
```

### 2. Install Terraform
Follow the official Terraform installation instructions for your operating system: Install Terraform[https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli]

### 3. Configure AWS Credentials
Ensure your AWS credentials are configured to interact with AWS services. You can configure AWS credentials using the AWS CLI:
```bash
aws configure
```
### 4. Initialize Terraform Configuration
```bash
terraform init
```

### 5. Plan and Apply Terraform Configuration
```bash
terraform plan
terraform apply
```

### 6. Test API Endpoints
You can test your API endpoints using a browser, curl, or Postman.
- Using curl for POST 
```bash
curl -X POST "https://kec9u3bswd.execute-api.us-west-2.amazonaws.com/prod/resume" \
     -H "Content-Type: application/json" \
     -d '{
           "job_applied": "Fox - Backend Developer Role",
           "CV_used": "https://resume-pdfs-bucket.s3.us-west-2.amazonaws.com/janeCV.pdf",
           "email_used": "jucakaeze@yahoo.com",
           "date_of_application": "22-07-2020"
         }'
```
- Using curl for GET 
```bash
curl -X GET "https://kec9u3bswd.execute-api.us-west-2.amazonaws.com/prod/resume/list"
```
