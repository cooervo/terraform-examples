provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_user" "user_example" {
  name = "Mateo_Cuervo"
}

resource "aws_iam_policy" "ec2_and_glacier_policy" {
  name = "GlacierAndEc2"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "glacier:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "policyAttachToUser" {
  name = "attachment"
  users = [aws_iam_user.user_example.name]
  policy_arn = aws_iam_policy.ec2_and_glacier_policy.arn
}
