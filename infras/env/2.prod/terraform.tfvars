environment                                    = "prod"
region                                         = "eastus"
common_prefix                                  = "namnh21894"
mssql_administrative_ad_service_principal_name = "terraform-sp"
mssql_database_zone_redundant                  = true
mssql_database_read_scale                      = true
mssql_database_max_size_gb                     = 40
mssql_database_sku_name                        = "ElasticPool"