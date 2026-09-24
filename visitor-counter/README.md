# Visitor Counter (monorepo)

This repository is reorganized into two folders:

- `backend/` - FastAPI backend and tests.
- `frontend/` - static frontend assets and image folders.

Backend quick start:

```bash
cd backend
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Frontend quick start (simple server):

```bash
cd frontend
python3 -m http.server 8001
# open http://localhost:8001
```

Run frontend tests:

```bash
cd frontend
npm test
```

Run both services with Docker Compose:

```bash
docker compose up --build
```

To run the services in the background (detached mode):

```bash
docker compose up --build -d
```

Backend will be available at http://localhost:8000
Front-end will be available at http://localhost:8001

Put multiple image folders under `frontend/images/` to serve different sets later.

## Deploy to Amazon ECS on Fargate

This runbook publishes the existing frontend and backend images to ECR and runs them as separate Fargate services behind an internet-facing Application Load Balancer (ALB). The ALB serves the frontend on port 80 and the API on port 8000. These instructions describe creating AWS resources; no deployment has been run in an AWS account.

### Requirements, costs, and data

You need an AWS account, AWS CLI v2 configured for it, Docker Buildx, permissions for ECR/ECS/IAM/ALB/EFS/CloudWatch, and a VPC spanning at least two Availability Zones. Put the ALB in public subnets. Tasks may use private subnets with NAT/VPC endpoints or public subnets with public IP assignment. Task security groups should accept app traffic only from the ALB security group.

Fargate task storage is temporary. For a counter that survives task replacement, mount encrypted EFS at `/data` in the backend task. Keep the backend desired count at one: this app is not designed for multiple SQLite writers. For production scaling, replace SQLite with RDS or DynamoDB. ALB, Fargate, EFS, and ECR may incur charges; check regional pricing and delete resources when finished.

### 1. Build and push images

From `visitor-counter/`, set your account and region. Change the example region:

```bash
export AWS_REGION=ap-south-1
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export IMAGE_TAG=latest
aws ecr create-repository --repository-name visitor-counter-backend --region "$AWS_REGION" --image-scanning-configuration scanOnPush=true
aws ecr create-repository --repository-name visitor-counter-frontend --region "$AWS_REGION" --image-scanning-configuration scanOnPush=true
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
```

Build and publish both images (use `linux/arm64` and ARM64 task architecture if deploying ARM tasks):

```bash
docker build --platform linux/amd64 -t visitor-counter-backend:$IMAGE_TAG backend
docker tag visitor-counter-backend:$IMAGE_TAG "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/visitor-counter-backend:$IMAGE_TAG"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/visitor-counter-backend:$IMAGE_TAG"
docker build --platform linux/amd64 -t visitor-counter-frontend:$IMAGE_TAG frontend
docker tag visitor-counter-frontend:$IMAGE_TAG "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/visitor-counter-frontend:$IMAGE_TAG"
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/visitor-counter-frontend:$IMAGE_TAG"
```

Use a new `IMAGE_TAG` for each release.

### 2. Create networking and persistent storage

In the AWS console, create an ECS cluster with Fargate capacity and an internet-facing ALB in two public subnets. Allow inbound TCP 80 and 8000 on the ALB security group (limit client IPs where practical). Create a task security group allowing TCP 8001 and 8000 only from the ALB security group. Private task subnets need NAT or suitable VPC endpoints to pull ECR images and send CloudWatch logs.

For persistent counter data, create encrypted EFS with mount targets in task Availability Zones. Allow inbound NFS TCP 2049 to the EFS security group from the task security group. Create an EFS access point at `/visitor-counter` with POSIX UID/GID 1000 and directory permissions 0770. In the backend task definition, configure an EFS volume using that access point with transit encryption and mount it at `/data`. If EFS is omitted, task replacement loses the counter.

### 3. Create task definitions

Register two Linux Fargate task definitions with `awsvpc` networking. For a demo, 0.25 vCPU and 0.5 GB memory is sufficient (choose a valid Fargate CPU/memory pair). Use the ECS task execution role with `AmazonECSTaskExecutionRolePolicy` so ECS can pull from ECR and write CloudWatch logs. Configure a CloudWatch log group for each container.

Backend container configuration:

- Image: `$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/visitor-counter-backend:$IMAGE_TAG`
- Container port: TCP 8000.
- Environment: `COUNTER_DB_PATH=/data/counter.db` and `CORS_ALLOWED_ORIGINS=http://<ALB-DNS-NAME>` (the exact frontend origin, no trailing slash).
- Health check: `python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"`.
- Mount the EFS volume at `/data`.

Frontend container configuration:

- Image: `$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/visitor-counter-frontend:$IMAGE_TAG`
- Container port: TCP 8001.
- Health check: `python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8001/')"`.

Set health check interval 30 seconds, timeout 5 seconds, retries 3, and start period 10 seconds. The frontend accepts the backend API base URL in the `backend` query parameter.

### 4. Configure the ALB

Create two HTTP target groups with target type **IP**: frontend port 8001 with health path `/`, and backend port 8000 with health path `/health`. Add an ALB listener on port 80 forwarding to the frontend group and a listener on port 8000 forwarding to the backend group.

For a public production deployment, use a domain and ACM certificate and serve both app and API over HTTPS. Configure the frontend's backend URL with the HTTPS API origin; an HTTPS page cannot call an HTTP API.

### 5. Create services and verify

Create one ECS service for each task definition. Select Fargate, desired count 1, your VPC and task security group, and attach each service to its matching target group and container port (`frontend:8001`, `backend:8000`). Enable deployment circuit breaker and rollback if available. Enable public IP assignment only if tasks are in public subnets.

Set backend `CORS_ALLOWED_ORIGINS` to the exact frontend origin. Since the ALB DNS name is learned after ALB creation, register a new backend task definition revision and redeploy once known. Wait for one running task per service and healthy targets in both target groups. Open:

```text
http://<ALB-DNS-NAME>/?backend=http%3A%2F%2F<ALB-DNS-NAME>%3A8000
```

Check `http://<ALB-DNS-NAME>:8000/health` and `http://<ALB-DNS-NAME>:8000/counter`. If the page loads without a count, inspect browser CORS/network errors, the backend CloudWatch logs, target health, and the exact allowed origin.

### 6. Update and clean up

For a release, push new tagged images, register task definition revisions with those image tags, and update both ECS services. EFS keeps data across task replacement.

To stop charges, scale services to zero and delete ECS services/cluster, ALB/listeners/target groups, EFS filesystem/mount targets, security groups, and CloudWatch log groups. Delete ECR repositories only if the images are no longer needed. Keep EFS to preserve the count.

## API reference

- `GET /health` - service health.
- `GET /counter` - current global count.
- `POST /increment` - increments the count.
- `POST /reset` - resets it to zero.
- `/docs` - interactive FastAPI API reference.

