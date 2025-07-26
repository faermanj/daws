import aws_cdk as core
import aws_cdk.assertions as assertions

from simple_web_cdk.simple_web_cdk_stack import SimpleWebCdkStack

# example tests. To run these tests, uncomment this file along with the example
# resource in simple_web_cdk/simple_web_cdk_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = SimpleWebCdkStack(app, "simple-web-cdk")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
