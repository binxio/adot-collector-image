FROM public.ecr.aws/aws-observability/aws-otel-collector:latest

ARG CONFIG_FILE # This is the path to the config file (e.g. ecs-amp-xray-config.yaml)

COPY $CONFIG_FILE /etc/ecs/adot-collector-config.yaml
CMD ["--config=/etc/ecs/adot-collector-config.yaml"]