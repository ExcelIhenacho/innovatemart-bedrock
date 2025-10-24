# ==============================================================================
# BONUS: Managed Databases (RDS PostgreSQL, RDS MySQL)
# ==============================================================================

# ==============================================================================
# Security Group for RDS Instances
# ==============================================================================

resource "aws_security_group" "rds" {
  name_prefix = "${var.cluster_name}-rds-"
  description = "Security group for RDS instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

# ==============================================================================
# DB Subnet Group
# ==============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}

# ==============================================================================
# RDS PostgreSQL for Orders Service
# ==============================================================================

resource "random_password" "orders_db_password" {
  length  = 16
  special = true
}

resource "aws_db_instance" "orders_postgresql" {
  identifier     = "${var.cluster_name}-orders-db"
  engine         = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "orders"
  username = "orders_user"
  password = random_password.orders_db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.cluster_name}-orders-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  deletion_protection = false

  tags = {
    Name        = "${var.cluster_name}-orders-postgresql"
    Service     = "orders"
    ManagedBy   = "Terraform"
  }
}

# ==============================================================================
# RDS MySQL for Catalog Service
# ==============================================================================

resource "random_password" "catalog_db_password" {
  length  = 16
  special = true
}

resource "aws_db_instance" "catalog_mysql" {
  identifier     = "${var.cluster_name}-catalog-db"
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "catalog"
  username = "catalog_user"
  password = random_password.catalog_db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.cluster_name}-catalog-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  deletion_protection = false

  tags = {
    Name        = "${var.cluster_name}-catalog-mysql"
    Service     = "catalog"
    ManagedBy   = "Terraform"
  }
}

# ==============================================================================
# Kubernetes Secrets for Database Credentials
# ==============================================================================

resource "kubernetes_secret" "orders_db" {
  metadata {
    name      = "orders-db-credentials"
    namespace = "retail-store"
  }

  data = {
    DB_HOST     = aws_db_instance.orders_postgresql.address
    DB_PORT     = tostring(aws_db_instance.orders_postgresql.port)
    DB_NAME     = aws_db_instance.orders_postgresql.db_name
    DB_USER     = aws_db_instance.orders_postgresql.username
    DB_PASSWORD = random_password.orders_db_password.result
    DB_ENDPOINT = "${aws_db_instance.orders_postgresql.address}:${aws_db_instance.orders_postgresql.port}"
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.retail_store]
}

resource "kubernetes_secret" "catalog_db" {
  metadata {
    name      = "catalog-db-credentials"
    namespace = "retail-store"
  }

  data = {
    DB_HOST     = aws_db_instance.catalog_mysql.address
    DB_PORT     = tostring(aws_db_instance.catalog_mysql.port)
    DB_NAME     = aws_db_instance.catalog_mysql.db_name
    DB_USER     = aws_db_instance.catalog_mysql.username
    DB_PASSWORD = random_password.catalog_db_password.result
    DB_ENDPOINT = "${aws_db_instance.catalog_mysql.address}:${aws_db_instance.catalog_mysql.port}"
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.retail_store]
}

# ==============================================================================
# Create retail-store namespace if it doesn't exist
# ==============================================================================

resource "kubernetes_namespace" "retail_store" {
  metadata {
    name = "retail-store"
    labels = {
      name      = "retail-store"
      project   = var.project_name
      managedBy = "terraform"
    }
  }
}

