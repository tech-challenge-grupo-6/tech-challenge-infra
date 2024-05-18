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

resource "aws_ecr_repository" "controladorpagamento-app" {
  name                 = "controladorpagamento-app"
  image_tag_mutability = "MUTABLE"
  tags = {
    "techchallenge" = ""
  }
  tags_all = {
    "techchallenge" = ""
  }
}

resource "aws_ecr_repository" "controladorproducao-app" {
  name                 = "controladorproducao-app"
  image_tag_mutability = "MUTABLE"
  tags = {
    "techchallenge" = ""
  }
  tags_all = {
    "techchallenge" = ""
  }
}

# EKS CLuester

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "tech-challenge-eks"
}

data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.29-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI account ID
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "tech-challenge-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "techchallenge" = ""
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
    "techchallenge"                               = ""
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
    "techchallenge"                               = ""
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      tags = {
        "techchallenge" = ""
      }
    }
  }
  tags = {
    "techchallenge" = ""
  }
}


# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.7.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
  tags = {
    "techchallenge" = ""
  }
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.20.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon"     = "ebs-csi"
    "terraform"     = "true"
    "techchallenge" = ""
  }
}

# Cache

resource "aws_security_group" "redis_security_group" {
  name        = "redis-security-group"
  description = "Security group for Redis"
  vpc_id      = module.vpc.vpc_id # Assuming your EKS module exposes the VPC ID

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust this to your needs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    techchallenge = "Cache Security Group"
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = module.vpc.private_subnets # Assuming your EKS module exposes the subnet IDs

  tags = {
    techchallenge = "Cache Subnet Group"
  }
}

resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "controlador-pedidos-cache"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids = [aws_security_group.redis_security_group.id]

  tags = {
    techchallenge = "Redis Cache"
  }
}
