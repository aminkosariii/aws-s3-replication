resource "aws_s3_bucket" "mybucket"{
  bucket = var.bucket_name
  force_destroy = true
}

#Resource to add bucket policy to a bucket 
resource "aws_s3_bucket_policy" "mybucket_access" {
  bucket = aws_s3_bucket.mybucket.id
  policy = data.aws_iam_policy_document.mybucket_policy.json
}

#DataSource to generate a policy document
data "aws_iam_policy_document" "mybucket_policy" {
  statement {
    principals {
	  type = "*"
	  identifiers = ["*"]
	}

    actions = [
      "s3:GetObject",
    ]

    resources = [
      aws_s3_bucket.mybucket.arn,
      "${aws_s3_bucket.mybucket.arn}/*",
    ]
  }
}
# versioning public s3
resource "aws_s3_bucket_acl" "mybucket_acl" {
  bucket = aws_s3_bucket.mybucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "mybucket_versioning" {
  bucket = aws_s3_bucket.mybucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

#creating and versiong replication
resource "aws_s3_bucket" "mybucket_destination" {
  bucket = "${var.bucket_name}-destination"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "mybucket_destination_versioning" {
  bucket = aws_s3_bucket.mybucket_destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

# iam role for replication
data "aws_iam_policy_document" "mybucket_replication" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.mybucket.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${aws_s3_bucket.mybucket.arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["${aws_s3_bucket.mybucket_destination.arn}/*"]
  }
}

resource "aws_iam_role" "mybucket_replication" {
  name               = "iam-role-replication-public"
  assume_role_policy = data.aws_iam_policy_document.mybucket_replication.json
}

resource "aws_iam_policy" "mybucket_replication" {
  name   = "tf-iam-role-policy-replication-12345"
  policy = data.aws_iam_policy_document.mybucket_replication.json
}

resource "aws_iam_role_policy_attachment" "mybucket_replication" {
  role       = aws_iam_role.mybucket_replication.name
  policy_arn = aws_iam_policy.mybucket_replication.arn
}


resource "aws_s3_bucket_replication_configuration" "mybucket_replication" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.mybucket_versioning]

  role   = aws_iam_role.mybucket_replication.arn
  bucket = aws_s3_bucket.mybucket.id

  rule {
    id = "rule-1"
    status = "Enabled"

    filter {
      prefix = "documents/"
    }


    destination {
      bucket        = aws_s3_bucket.mybucket_destination.arn
      storage_class = "GLACIER"
    }
  }
}

# server side encryption 
resource "aws_kms_key" "s3enc" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 20
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3SSE" {
  bucket = aws_s3_bucket.mybucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3enc.arn
      sse_algorithm     = "aws:kms"
    }
  }
}