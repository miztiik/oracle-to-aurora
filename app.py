#!/usr/bin/env python3

from aws_cdk import core

from oracle_to_aurora.oracle_to_aurora_stack import OracleToAuroraStack


app = core.App()
OracleToAuroraStack(app, "oracle-to-aurora")

app.synth()
