module "s3_replication_v1" {
  source      = "./s3-rep"
  bucket_name = "s3v1-1234567"
}

module "s3_replication_v2" {
  source      = "./s3-rep"
  bucket_name = "s3v2-1234567"
}
