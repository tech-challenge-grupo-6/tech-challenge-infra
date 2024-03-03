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

# Images Repositories

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

# EKS CLuester

data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.29-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI account ID
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = "tech-challenge-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "techchallenge"                        = ""
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/elb"               = "1"
    "techchallenge"                        = ""
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"      = "1"
    "techchallenge"                        = ""
  }
}

resource "aws_iam_role" "esk_node_role" {
  name = "esk_node_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    "techchallenge" = ""
  }
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.esk_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.esk_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.esk_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "tech-challenge-eks"
  cluster_version = "1.29"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  tags = {
    "techchallenge" = ""
  }

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    eks_nodes = {
      desired_capacity = 1
      max_capacity     = 1
      min_capacity     = 1

      instance_type = "t3.micro"

      root_volume_size = "20"
      root_volume_type = "gp2"

      ami_id      = data.aws_ami.eks_worker.id
      iam_role_id = aws_iam_role.esk_node_role

      additional_tags = {
        Environment   = "test"
        Name          = "eks-worker-node"
        techchallenge = ""
      }
      tags = {
        "techchallenge" = ""
      }
    }
  }
}
