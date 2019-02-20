publisher_root_domain     = "fb-publisher-dev.apps.cloud-platform-live-0.k8s.integration.dsd.io"

cluster_security_groups   = ["sg-7e8cf203"]

rds_storage_gb            = 10
rds_backup_retention_days = 2
rds_instance_class        = "db.t2.small"
rds_multi_az              = true
rds_encrypted             = true
rds_publicly_accessible   = false
# rds_username
# rds_password

tag_is_production         = false
