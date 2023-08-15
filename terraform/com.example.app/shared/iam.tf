data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "${var.project_name}-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy.name
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.role.name
}


resource "aws_iam_role" "role" {
  name                = "${var.project_name}-instance-role"
  path                = "/"
  managed_policy_arns = [
    aws_iam_policy.codedeploy_install.arn,
    aws_iam_policy.describe_network_interfaces.arn,
    aws_iam_policy.read_codedeploy_artifacts.arn,
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
  ]

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "describe_network_interfaces" {
  name = "${var.project_name}-describe-network-interfaces"
  policy = jsonencode({
    "Version" : "2012-10-17", "Statement" : [
      {
        "Sid" : "VisualEditor0", "Effect" : "Allow", "Action" : "ec2:DescribeNetworkInterfaces", "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_policy" "read_codedeploy_artifacts" {
  name = "${var.project_name}-read-codedeploy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17", "Statement" : [
      {
        "Sid" : "fetchObjects", "Effect" : "Allow", "Action" : [
        "s3:GetObjectAcl", "s3:GetObject", "s3:GetObjectVersionAcl", "s3:ListBucket", "s3:GetObjectVersion"
      ], "Resource" : [
        "arn:aws:s3:::${aws_s3_bucket.codedeploy_artifacts.bucket}/*",
        "arn:aws:s3:::${aws_s3_bucket.codedeploy_artifacts.bucket}",
      ]
      }, {
        "Sid" : "headBucket", "Effect" : "Allow", "Action" : "s3:HeadBucket",
        "Resource" : "*"
      }
    ]
    })
}

resource "aws_iam_policy" "reassociate_elastic_ip" {
  name   = "${var.project_name}-reassociate-eip"
  policy = jsonencode({
    "Version" : "2012-10-17", "Statement" : [
      {
        "Sid" : "VisualEditor0", "Effect" : "Allow", "Action" : [
        "ec2:DisassociateAddress", "ec2:DescribeAddresses", "ec2:AssociateAddress", "ec2:AllocateAddress"
      ], "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_read_only_access" {
  name = "${var.project_name}-ec2-ro-access"
  policy = jsonencode(
    {
      "Version" : "2012-10-17", "Statement" : [
      {
        "Effect" : "Allow", "Action" : "ec2:Describe*", "Resource" : "*"
      }, {
        "Effect" : "Allow", "Action" : "elasticloadbalancing:Describe*", "Resource" : "*"
      }, {
        "Effect" : "Allow", "Action" : [
          "cloudwatch:ListMetrics", "cloudwatch:GetMetricStatistics", "cloudwatch:Describe*"
        ], "Resource" : "*"
      }, {
        "Effect" : "Allow", "Action" : "autoscaling:Describe*", "Resource" : "*"
      }
    ]
    })
}

resource "aws_iam_policy" "codedeploy_install" {
  name = "${var.project_name}-ami-codedeploy-installation"
  policy = jsonencode(
    {
      "Version" : "2012-10-17", "Statement" : [
      {
        "Effect" : "Allow", "Action" : [
        "s3:Get*", "s3:List*"
      ], "Resource" : [
        "arn:aws:s3:::aws-codedeploy-us-east-2/*", "arn:aws:s3:::aws-codedeploy-us-east-1/*",
        "arn:aws:s3:::aws-codedeploy-us-west-1/*", "arn:aws:s3:::aws-codedeploy-us-west-2/*",
        "arn:aws:s3:::aws-codedeploy-ca-central-1/*", "arn:aws:s3:::aws-codedeploy-eu-west-1/*",
        "arn:aws:s3:::aws-codedeploy-eu-west-2/*", "arn:aws:s3:::aws-codedeploy-eu-west-3/*",
        "arn:aws:s3:::aws-codedeploy-eu-central-1/*", "arn:aws:s3:::aws-codedeploy-ap-northeast-1/*",
        "arn:aws:s3:::aws-codedeploy-ap-northeast-2/*", "arn:aws:s3:::aws-codedeploy-ap-southeast-1/*",
        "arn:aws:s3:::aws-codedeploy-ap-southeast-2/*", "arn:aws:s3:::aws-codedeploy-ap-south-1/*",
        "arn:aws:s3:::aws-codedeploy-sa-east-1/*"
      ]
      }
    ]
    })
}