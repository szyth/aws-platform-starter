# -----------------------------------------------------------------------------
# ECR: private container registry for one service, plus the IAM role its CI
# pipeline assumes (through GitHub OIDC) to push images. Nothing else.
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "this" {
  name = var.repository_name

  # A tag (the git SHA) can be pushed once and never overwritten, so a running
  # image always maps to exactly one commit.
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true # basic CVE scan of every pushed image
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Keep storage bounded: expire everything beyond the newest N images.
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the last ${var.image_retention_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.image_retention_count
      }
      action = { type = "expire" }
    }]
  })
}

# ---- CI push role -------------------------------------------------------------
# Trusted only by the listed GitHub repo/branch, allowed only to push to THIS repo.

data "aws_iam_policy_document" "push_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.push_subjects
    }
  }
}

resource "aws_iam_role" "push" {
  name                 = "${var.repository_name}-ci-push"
  assume_role_policy   = data.aws_iam_policy_document.push_trust.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "push" {
  # The docker login token is account-wide; AWS doesn't allow scoping it.
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Everything else is limited to this one repository.
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:DescribeImages",
    ]
    resources = [aws_ecr_repository.this.arn]
  }
}

resource "aws_iam_role_policy" "push" {
  name   = "ecr-push"
  role   = aws_iam_role.push.id
  policy = data.aws_iam_policy_document.push.json
}
