# Terraform EC2 ALB AutoScaling Project

## Overview
This project provisions a highly available AWS infrastructure using Terraform.  
It deploys multiple EC2 instances behind an Application Load Balancer (ALB) with Auto Scaling and CloudWatch monitoring.

The infrastructure is completely automated using Infrastructure as Code (IaC) principles.

---

## Features

- EC2 Launch Templates
- Auto Scaling Groups
- Application Load Balancer (ALB)
- Path-based Routing
- CloudWatch Scaling Policies
- Nginx Web Server Setup using User Data
- High Availability Architecture
- Terraform-based Infrastructure Automation

---

## Architecture

- Home application served on:
  - `/`

- Cloth application served on:
  - `/cloth`

- ALB routes traffic based on URL path patterns.

---

## Technologies Used

- Terraform
- AWS EC2
- AWS Auto Scaling
- AWS Application Load Balancer
- AWS CloudWatch
- Nginx
- Linux

---

## Project Structure

```bash
.
├── main.tf
