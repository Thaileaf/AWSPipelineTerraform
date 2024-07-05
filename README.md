# League Data Collection Infrastructure

This repository contains Terraform configurations to quickly spin up AWS infrastructure for manual League of Legends data collection, and to quickly destroy them afterwards.

## Overview

This Terraform script sets up the following AWS resources:

- VPC with a private subnet
- EC2 Instance Connect Endpoint
- EC2 instance for data collection
- S3 bucket for data storage
- Necessary security groups and IAM roles
