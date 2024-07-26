# LifeCycleHook for AutoScalingGroup (NodeGroup)
## Ec2Ins LcHook is for ENI Attach Lambda Call
resource "aws_autoscaling_lifecycle_hook" "LchookEc2InsNg1" {
  name                   = "${var.eks_cluster_name}-nodegroup-LchookEc2InsNg1"
  autoscaling_group_name = module.eks.self_managed_node_groups_autoscaling_group_names[0]
  default_result         = "ABANDON"
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

resource "aws_autoscaling_lifecycle_hook" "LchookEc2TermNg1" {
  name                   = "${var.eks_cluster_name}-nodegroup-LchookEc2TermNg1"
  autoscaling_group_name = module.eks.self_managed_node_groups_autoscaling_group_names[0]
  default_result         = "CONTINUE"
  heartbeat_timeout      = 300
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}

resource "aws_iam_role" "RoleLambdaAttach2ndEni" {
  name = "${var.eks_cluster_name}-nodegroup-RoleLambdaAttach2ndEni"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "PolicyLambdaAttach2ndEni" {
  name = "${var.eks_cluster_name}-nodegroup-PolicyLambdaAttach2ndEni"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
                "ec2:CreateNetworkInterface",
                "ec2:DescribeInstances",
                "ec2:DetachNetworkInterface",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:DescribeSubnets",
                "autoscaling:CompleteLifecycleAction",
                "ec2:DeleteTags",
                "ec2:DescribeNetworkInterfaces",
                "ec2:ModifyInstanceAttribute",
                "ec2:CreateTags",
                "ec2:DeleteNetworkInterface",
                "ec2:AttachNetworkInterface",
                "autoscaling:DescribeAutoScalingGroups",
                "ec2:TerminateInstances"            
        ]
        Effect   = "Allow"
        Resource = "*"
      },{
        Action   = [
                "logs:CreateLogStream",
                "logs:PutLogEvents"          
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },{
        Action   = [
              "logs:CreateLogGroup"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "PolicyLambdaAttach2ndEni" {
  role       = aws_iam_role.RoleLambdaAttach2ndEni.name
  policy_arn = aws_iam_policy.PolicyLambdaAttach2ndEni.arn
}

resource "aws_lambda_function" "LambdaAttach2ndENI" {
  function_name = "${var.eks_cluster_name}-nodegroup-LambdaAttach2ndENI"
  role          = aws_iam_role.RoleLambdaAttach2ndEni.arn
  handler       = "lambda_function.lambda_handler"
  s3_bucket     = var.attach_2nd_eni_lambda_s3_bucket
  s3_key        = var.attach_2nd_eni_lambda_s3_key
  timeout       = 60

  runtime = "python3.8"

  environment {
    variables = {
      SubnetIds = var.multus_subnets
      SecGroupIds = var.multus_security_group_id
      useStaticIPs = var.use_ips_from_start_of_subnet
      ENITags = var.interface_tags
      SourceDestCheckEnable = var.source_dest_check_enable
    }
  }

  depends_on = [ 
    module.eks
    ]
}

resource "aws_cloudwatch_event_rule" "NewInstanceEventRule" {
  name        = "${var.eks_cluster_name}-nodegroup-NewInstanceEventRule"

  event_pattern = jsonencode({
    detail-type = [
      "EC2 Instance-launch Lifecycle Action",
      "EC2 Instance-terminate Lifecycle Action"
    ]
    detail = {
        AutoScalingGroupName: [module.eks.self_managed_node_groups_autoscaling_group_names[0]]
    }
    source = [
        "aws.autoscaling"
    ]
  })
}

resource "aws_cloudwatch_event_target" "NewInstanceEvent" {
  rule      = aws_cloudwatch_event_rule.NewInstanceEventRule.name
  arn       = aws_lambda_function.LambdaAttach2ndENI.arn
}


resource "aws_lambda_permission" "PermissionForEventsToInvokeLambda" {
  statement_id  = "${var.eks_cluster_name}-nodegroup-permission-to-invoke-lambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.LambdaAttach2ndENI.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.NewInstanceEventRule.arn
}

data "archive_file" "lambda_function_file" {
  type = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "asg_instances_auto_restart" {
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "${var.eks_cluster_name}-nodegroup-asg_instances_auto_restart"
  handler          = "lambda_function.handler"
  runtime          = "python3.8"
  role             = aws_iam_role.RoleLambdaAttach2ndEni.arn
  source_code_hash = data.archive_file.lambda_function_file.output_base64sha256
 
}

resource "aws_lambda_invocation" "restart_asg_instances" {
  function_name = aws_lambda_function.asg_instances_auto_restart.function_name

  input = jsonencode({
     "AsgName": module.eks.self_managed_node_groups_autoscaling_group_names[0]
  })

  depends_on = [
    aws_lambda_function.LambdaAttach2ndENI,
    module.eks_blueprints_addons,
    kubernetes_manifest.flux_instance  
  ]  
}