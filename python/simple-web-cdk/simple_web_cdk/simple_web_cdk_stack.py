from aws_cdk import (
    Duration,
    Stack,
    aws_sqs as sqs,
)
from constructs import Construct
from aws_cdk import aws_ec2 as ec2
from aws_cdk import aws_elasticloadbalancingv2 as elbv2, aws_ec2 as ec2
from aws_cdk import aws_ecs as ecs
import boto3


class SimpleWebCdkStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
<<<<<<< HEAD
        self.networking()
        self.alb()
        # database()
        self.cluster()
        # app_service()

    def app_services(self):
        task_definition = ecs.FargateTaskDefinition(
            self, "Docker2048TaskDef",
            cpu=256,
            memory_limit_mib=512
        )

        container = task_definition.add_container(
            "Docker2048Container",
            image=ecs.ContainerImage.from_registry("evilroot/docker-2048"),
            logging=ecs.LogDrivers.aws_logs(stream_prefix="Docker2048")
        )

        container.add_port_mappings(
            ecs.PortMapping(container_port=80)
        )

        ecs.FargateService(
            self, "Docker2048Service",
            cluster=self.ecs_cluster,
            task_definition=task_definition,
            desired_count=1,
            assign_public_ip=True,
            vpc_subnets=ec2.SubnetSelection(subnet_type=ec2.SubnetType.PUBLIC)
        )
        
    def cluster(self):
        self.ecs_cluster = ecs.Cluster(
            self, "SimpleWebCdkCluster",
            vpc=self.vpc,
            container_insights=True
        )

        # Add Fargate capacity providers (Fargate and Fargate Spot)
        self.ecs_cluster.enable_fargate_capacity_providers()

    def alb(self):
        vpc = self.vpc
        
        alb = elbv2.ApplicationLoadBalancer(
            self, "SimpleWebCdkALB",
            vpc=vpc,
            internet_facing=True,
            vpc_subnets=ec2.SubnetSelection(subnet_type=ec2.SubnetType.PRIVATE_ISOLATED)
        )

        listener = alb.add_listener(
            "Listener",
            port=80,
            open=True
        )

        listener.add_action(
            "DefaultFixedResponse",
            action=elbv2.ListenerAction.fixed_response(
                status_code=503,
                message_body="service unavailable",
                content_type="text/plain"
            )
        )
        
    def networking(self):
        # Get the list of availability zones in the current region and pick the first 3
        # TODO: is it possible to fetch the AZs from the CDK context instead of boto3?
        azs = self.availability_zones[:3]
        
        self.vpc = ec2.Vpc(
            self, "SimpleWebCdkVpc",
            cidr="10.0.0.0/16",
            availability_zones=azs,
            subnet_configuration=[
            ec2.SubnetConfiguration(
                name="PublicSubnet",
                subnet_type=ec2.SubnetType.PUBLIC,
                cidr_mask=24
            ),
            ec2.SubnetConfiguration(
                name="PrivateSubnet",
                subnet_type=ec2.SubnetType.PRIVATE_ISOLATED,
                cidr_mask=24
            )
            ],
            nat_gateways=0
        )
=======

        # The code that defines your stack goes here

        # example resource
        # queue = sqs.Queue(
        #     self, "SimpleWebCdkQueue",
        #     visibility_timeout=Duration.seconds(300),
        # )
>>>>>>> 04f265a (wip)
