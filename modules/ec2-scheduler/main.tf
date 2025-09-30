#--------------------------------------------------
# IAM Role for SSM Automation
#--------------------------------------------------
resource "aws_iam_role" "ssm_ec2_startstop" {
  name = "${var.resource_name_prefix}-ssm-automation-ec2-auto-startstop-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ssm.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ssm_ec2_startstop" {
  name = "${var.resource_name_prefix}-ssm-automation-ec2-auto-startstop-policy"
  role = aws_iam_role.ssm_ec2_startstop.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action: ["ec2:StartInstances"],
        Resource: "arn:aws:ec2:${var.region}:${var.account_id}:instance/*",
        Condition: { "StringEquals": { "ec2:ResourceTag/AutoStart": "true" } }
      },
      {
        Effect: "Allow",
        Action: ["ec2:StopInstances"],
        Resource: "arn:aws:ec2:${var.region}:${var.account_id}:instance/*",
        Condition: { "StringEquals": { "ec2:ResourceTag/AutoStop": "true" } }
      },
      {
        Effect: "Allow",
        Action: ["ec2:DescribeInstances"],
        Resource: "*"
      }
    ]
  })
}

#--------------------------------------------------
# IAM Role for EventBridge Scheduler
#--------------------------------------------------
resource "aws_iam_role" "scheduler_ec2_startstop" {
  name = "${var.resource_name_prefix}-scheduler-ec2-auto-startstop-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "scheduler.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_ec2_startstop" {
  name = "${var.resource_name_prefix}-scheduler-ec2-auto-startstop-policy"
  role = aws_iam_role.scheduler_ec2_startstop.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action: [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution",
          "ssm:DescribeInstanceInformation"
        ],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: [
          "tag:GetResources",
          "resource-groups:ListGroupResources"
        ],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: ["iam:PassRole"],
        Resource: aws_iam_role.ssm_ec2_startstop.arn,
        Condition: { "StringEquals": { "iam:PassedToService": "ssm.amazonaws.com" } }
      }
    ]
  })
}

#--------------------------------------------------
# Resource Groups for EC2 Auto Start/Stop
#--------------------------------------------------
resource "aws_resourcegroups_group" "ec2_autostart" {
  name        = "${var.resource_name_prefix}-ec2-autostart-group"
  description = "EC2 instances for auto start in ${var.environment} environment"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::EC2::Instance"]
      TagFilters = [
        {
          Key    = "AutoStart"
          Values = ["true"]
        },
        {
          Key    = "Environment"
          Values = [var.environment]
        }
      ]
    })
  }
}

resource "aws_resourcegroups_group" "ec2_autostop" {
  name        = "${var.resource_name_prefix}-ec2-autostop-group"
  description = "EC2 instances for auto stop in ${var.environment} environment"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::EC2::Instance"]
      TagFilters = [
        {
          Key    = "AutoStop"
          Values = ["true"]
        },
        {
          Key    = "Environment"
          Values = [var.environment]
        }
      ]
    })
  }
}

#--------------------------------------------------
# EventBridge Scheduler for EC2 Start/Stop
#--------------------------------------------------
resource "aws_scheduler_schedule" "ec2_autostart" {
  name        = "${var.resource_name_prefix}-ec2-autostart"
  description = "Start EC2 instances tagged AutoStart=true at 07:00 JST on weekdays"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.start_schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ssm:startAutomationExecution"
    role_arn = aws_iam_role.scheduler_ec2_startstop.arn

    input = jsonencode({
      DocumentName         = "AWS-StartEC2Instance",
      TargetParameterName  = "InstanceId",
      Parameters           = {
        AutomationAssumeRole = [aws_iam_role.ssm_ec2_startstop.arn]
      },
      Targets = [
        { Key = "ResourceGroup", Values = [aws_resourcegroups_group.ec2_autostart.name] }
      ]
    })
  }
}

resource "aws_scheduler_schedule" "ec2_autostop" {
  name        = "${var.resource_name_prefix}-ec2-autostop"
  description = "Stop EC2 instances tagged AutoStop=true at 18:00 JST on weekdays"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.stop_schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ssm:startAutomationExecution"
    role_arn = aws_iam_role.scheduler_ec2_startstop.arn

    input = jsonencode({
      DocumentName         = "AWS-StopEC2Instance",
      TargetParameterName  = "InstanceId",
      Parameters           = {
        AutomationAssumeRole = [aws_iam_role.ssm_ec2_startstop.arn]
      },
      Targets = [
        { Key = "ResourceGroup", Values = [aws_resourcegroups_group.ec2_autostop.name] }
      ]
    })
  }
}
