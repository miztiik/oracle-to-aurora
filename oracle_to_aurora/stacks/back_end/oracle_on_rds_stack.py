from aws_cdk import aws_ec2 as _ec2
from aws_cdk import aws_rds as _rds
from aws_cdk import core
from aws_cdk.aws_rds import EngineVersion


class GlobalArgs:
    """
    Helper to define global statics
    """

    OWNER = "MystiqueAutomation"
    ENVIRONMENT = "production"
    REPO_NAME = "oracle-to-aurora"
    SOURCE_INFO = f"https://github.com/miztiik/{REPO_NAME}"
    VERSION = "2020_11_03"
    MIZTIIK_SUPPORT_EMAIL = ["mystique@example.com", ]


class OracleOnRdsStack(core.Stack):

    def __init__(
        self,
        scope: core.Construct, id: str,
        vpc,
        rds_instance_size: str,
        stack_log_level: str,
        **kwargs
    ) -> None:
        super().__init__(scope, id, **kwargs)

        # DB Instance Class & Versions supported
        # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html#Concepts.DBInstanceClass.Support
        # oracle_rds_instance = _rds.DatabaseInstance(
        oracle_rds_instance = _rds.DatabaseInstanceFromSnapshot(
            self, "rds",
            snapshot_identifier="arn:aws:rds:us-east-1:833997227572:snapshot:dms-lab-oracle-source-snapshot01",
            database_name="ORACLEDB",
            # credentials=_rds.Credentials.from_username(
            #     username="dbmaster",
            #     password=core.SecretValue.plain_text(
            #         self.node.try_get_context("oracle_rds_password"))
            # ),
            engine=_rds.DatabaseInstanceEngine.ORACLE_EE,
            # instance_type=_ec2.InstanceType.of(
            #     _ec2.InstanceClass.BURSTABLE3,
            #     _ec2.InstanceSize.MICRO,
            # ),
            instance_type=_ec2.InstanceType(
                instance_type_identifier=rds_instance_size
            ),
            multi_az=False,
            vpc=vpc,
            vpc_subnets=_ec2.SubnetSelection(
                subnet_type=_ec2.SubnetType.PUBLIC),
            removal_policy=core.RemovalPolicy.DESTROY,
            deletion_protection=False,
            delete_automated_backups=True,
        )
        oracle_rds_instance.connections.allow_from(
            _ec2.Peer.any_ipv4(),
            _ec2.Port.tcp(1521),
            description="Allow Incoming Oracle Traffic FROM WORLD REALLY DO YOU WANT TO DO THIS :-("
        )

        ###########################################
        ################# OUTPUTS #################
        ###########################################
        output_0 = core.CfnOutput(
            self,
            "AutomationFrom",
            value=f"{GlobalArgs.SOURCE_INFO}",
            description="To know more about this automation stack, check out our github page."
        )
        output_1 = core.CfnOutput(
            self,
            "OracleEndPoint",
            value=f"{oracle_rds_instance.db_instance_endpoint_address}",
            description=f"Oracle DB Endpoint"
        )
        output_2 = core.CfnOutput(
            self,
            "OracleInstance",
            value=(
                f"https://console.aws.amazon.com/ec2/v2/home?region="
                f"{core.Aws.REGION}"
                f"#Instances:search="
                f"{oracle_rds_instance.db_instance_endpoint_address}"
            ),
            description=f"Administer Oracle DB from AWS Console"
        )
