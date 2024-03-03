terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "controladorpedidos-app" {
  name                 = "controladorpedidos-app"
  image_tag_mutability = "MUTABLE"
  tags = {
    "techchallenge" = ""
  }
  tags_all = {
    "techchallenge" = ""
  }
}

resource "aws_ecr_repository" "controladorpagamento-fake" {
  name                 = "controladorpagamento-fake"
  image_tag_mutability = "MUTABLE"
  tags = {
    "techchallenge" = ""
  }
  tags_all = {
    "techchallenge" = ""
  }
}
