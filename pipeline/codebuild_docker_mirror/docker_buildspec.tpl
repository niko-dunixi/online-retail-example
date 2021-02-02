version: 0.2

phases:
  build:
    commands:
      - docker pull docker.io/${image}
      - docker tag docker.io/${image} ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${image}
      - aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com
      - docker push ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${image}