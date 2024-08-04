# Deployment and Testing Guide

## Introduction
This guide provides instructions to deploy your Terraform configuration and automate deployment using github actions.

## Prerequisites
- Git installed on your local machine.


## Steps to Run the Project

### 1. Configure AWS Credentials

Ensure your AWS credentials are set up as GitHub secrets. In your GitHub repository, navigate to Settings > Secrets and variables > Actions and add the following secrets:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

### 2. Install Terraform
Follow the official Terraform installation instructions for your operating system: Install Terraform[https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli]

### 3. Push Code to Trigger Deployment
Any push to the main branch will automatically trigger the GitHub Actions workflow to deploy your infrastructure and Lambda functions.

### 4. Check GitHub Actions Workflow
Verify the deployment process in the Actions tab of your GitHub repository. Ensure that all steps complete successfully.

### 5. Test API Endpoints
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
