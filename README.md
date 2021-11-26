# custom AWS OTel Collector images

This repository uses the upstream version of [AWS Distro for OpenTelemetry](https://github.com/aws-observability/aws-otel-collector) and
simply wraps around it by having 2 ADOT Collector pipeline configurations available.

## prerequisites

To deploy the custom AWS OTel Collector images you need the following:

- Have `docker` installed
- Deploy the `ecr.yaml` stack or have other ECR image repositories available to host the images.

## explanation

We only provide a thin wrapper around the AWS OTel Collector in order to have more pipeline flexibility and have the images hosted in our own registry. It also allows for a more user-friendly sidecar experience as users now only need to specify an image.

## deploy to ECR

To deploy the custom AWS OTel Collector images to their respective ECR image repository:

```sh
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789101.dkr.ecr.us-east-1.amazonaws.com

docker build -t ecs-otel-amp-xray-collector:latest -f Dockerfile.amp-xray

docker tag ecs-otel-amp-xray-collector:latest 123456789101.dkr.ecr.us-east-1.amazonaws.com/ecs-otel-amp-xray-collector:latest

docker push 123456789101.dkr.ecr.us-east-1.amazonaws.com/ecs-otel-amp-xray-collector:latest
```

## usage

To use the custom AWS OTel Collector images in our task definition, we simply add a second container to the container definition, our sidecar. There's 2 properties that you need to set in the container definition for the sidecar.

- Image: Set it to the ECR image uri that's responsible for hosting the custom AWS OTel Collector.
- Environment variable (`AWS_PROMETHEUS_ENDPOINT`): set it to the AWS Prometheus remote write endpoint.

After adding the sidecar, the container definition should look as following:

```json
"containerDefinitions": [
      {
          "name": "sample-app",
          "image": "123456789101.dkr.ecr.us-east-1.amazonaws.com/sample-app:latest",
          "portMappings": [
              {
                  "containerPort": 5000,
                  "hostPort": 5000,
                  "protocol": "tcp"
              }
          ],
          "essential": true,
          "logConfiguration": {
              "logDriver": "awslogs",
              "options": {
                  "awslogs-create-group": "true",
                  "awslogs-group": "/ecs/sample-app-fam",
                  "awslogs-region": "eu-west-1",
                  "awslogs-stream-prefix": "ecs"
              }
          }
      },
      {
          "name": "ecs-otel-amp-xray-collector",
          "image": "123456789101.dkr.ecr.us-east-1.amazonaws.com/ecs-otel-amp-xray-collector:latest",
          "essential": true,
          "environment": [
              {
                  "name": "AWS_PROMETHEUS_ENDPOINT",
                  "value": "https://aps-workspaces.eu-west-1.amazonaws.com/workspaces/ws-3e63f902-e43a-40d0-a86e-1a47d16a6a71/api/v1/remote_write"
              }
          ],
          "logConfiguration": {
              "logDriver": "awslogs",
              "options": {
                  "awslogs-create-group": "True",
                  "awslogs-group": "/ecs/ecs-otel-amp-xray-collector",
                  "awslogs-region": "eu-west-1",
                  "awslogs-stream-prefix": "ecs"
              }
          }
      }
  ]
```

Note, be sure that the IAM role you've passed to your task definition has the following managed policies attached: _AWSXrayWriteOnlyAccess_, _AmazonECSTaskExecutionRolePolicy_, and _AmazonPrometheusRemoteWriteAccess_. After deploying the task definition (backed by a ECS service) it should start ingesting data into AWS Prometheus and AWS X-Ray.
