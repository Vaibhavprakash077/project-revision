# AWS Production CI/CD & Observability

A production-style AWS deployment of a containerized Flask application with automated CI/CD, scalable compute, load balancing, health checks, centralized logging, monitoring, and alerting.

## Architecture

![Architecture](architecture/architecture.png)

### Deployment Flow

**GitHub → GitHub Actions → Amazon ECR → EC2 Launch Template → Auto Scaling Group → Application Load Balancer → Target Group → Flask**

Monitoring and observability are provided through **Amazon CloudWatch**.

---

## What I Built

- Containerized Flask application using Docker
- Automated CI/CD pipeline using GitHub Actions
- Docker image build and publishing to Amazon ECR
- GitHub Actions authentication to AWS using IAM OIDC
- EC2 Launch Template for standardized instance configuration
- Auto Scaling Group for scalable EC2 deployment
- Internet-facing Application Load Balancer
- Target Group with multiple EC2 instances
- HTTP health checks for application instances
- CloudWatch dashboard for production monitoring
- CloudWatch alarms for unhealthy targets and HTTP 5XX responses
- Centralized Flask application logs using CloudWatch Logs

---

## CI/CD Pipeline

The deployment workflow follows this process:

```text
Developer
   ↓
GitHub Repository
   ↓
GitHub Actions
   ↓
Build & Test
   ↓
Docker Build
   ↓
Amazon ECR
   ↓
Launch Template
   ↓
Auto Scaling Group
   ↓
EC2 Instances
   ↓
Application Load Balancer
   ↓
Flask Application
```

AWS authentication from GitHub Actions uses **OIDC**, avoiding long-lived AWS access keys in GitHub.

---

## AWS Infrastructure

### Compute

- Amazon EC2
- EC2 Launch Template
- Auto Scaling Group

The Auto Scaling Group manages multiple application instances behind the load balancer.

### Container Registry

- Amazon ECR

Docker images are built through the CI/CD pipeline and pushed to Amazon ECR.

### Load Balancing

- Application Load Balancer
- Target Group
- HTTP listener
- Health checks

The ALB distributes incoming traffic across healthy EC2 targets.

### Monitoring

- Amazon CloudWatch Dashboard
- ALB Request Count
- ALB Target Response Time
- Healthy/Unhealthy Target Count
- ALB 5XX responses
- Auto Scaling CPU utilization
- Auto Scaling capacity

### Alerting

CloudWatch alarms were configured for:

- Unhealthy ALB targets
- Elevated target-side HTTP 5XX responses

### Logging

Application logs are centralized in:

```text
/phase17/flask
```

using Amazon CloudWatch Logs.

---

## Health Checks

The ALB Target Group performs HTTP health checks against:

```text
/health
```

Configuration used during the deployment included:

- Protocol: HTTP
- Health check path: `/health`
- Success code: `200`
- Health check interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 5 consecutive successes
- Unhealthy threshold: 2 consecutive failures

---

## Observability

The deployment includes a CloudWatch production dashboard covering:

- ALB traffic
- Target health
- Target response time
- HTTP 5XX responses
- ASG CPU utilization
- ASG capacity

This provides visibility into application availability, traffic, errors, and compute behavior.

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
├── architecture/
├── screenshots/
├── Dockerfile
├── app.py
├── requirements.txt
├── requirements-dev.txt
├── pyproject.toml
└── README.md
```

---

## Screenshots

### Production Architecture

![Production Architecture](architecture/architecture.png)

### Target Group

![Target Group](screenshots/target-group.png)

### CloudWatch Dashboard

![CloudWatch Dashboard](screenshots/cloudwatch-dashboard.png)

### CloudWatch Alarms

![CloudWatch Alarms](screenshots/cloudwatch-alarms.png)

### CloudWatch Logs

![CloudWatch Logs](screenshots/cloudwatch-logs.png)

---

## Key Learnings

This project helped me move beyond deploying individual AWS services and understand how they operate together as a production deployment architecture.

The main takeaway was understanding the complete relationship between:

**Application → Container → Registry → Compute → Auto Scaling → Load Balancer → Health Checks → Monitoring → Logs → Alerts**

It also gave me hands-on experience with automated AWS deployments through GitHub Actions and OIDC-based authentication.

---

## Future Improvements

Potential next improvements include:

- Infrastructure as Code with Terraform
- HTTPS using ACM
- Custom domain with Route 53
- Blue/green deployment strategy
- More advanced deployment automation
- Expanded observability and alerting
