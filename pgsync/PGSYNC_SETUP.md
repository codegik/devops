# PGSync Infrastructure Setup

This infrastructure now includes PostgreSQL, OpenSearch, and PGSync for real-time data synchronization between PostgreSQL and OpenSearch.

## Services Overview

### Core Services
- **PostgreSQL** (Port 5432): Primary database with sample data
- **OpenSearch** (Port 9200): Search and analytics engine
- **OpenSearch Dashboard** (Port 5601): Web interface for OpenSearch
- **PGSync** (Port 8080): Real-time sync service between PostgreSQL and OpenSearch
- **Redis** (Port 6379): Required by PGSync for coordination

### Existing Services
- **Prometheus** (Port 30300): Monitoring
- **Grafana** (Port 30400): Dashboards
- **Jenkins** (Port 30600): CI/CD
- **Docker Registry** (Port 30500): Container registry
- **Hello-buddy** (Port 3000): Sample application

## Database Schema

The PostgreSQL database includes three sample tables:

1. **users**: User information (id, name, email, created_at, updated_at)
2. **products**: Product catalog (id, name, description, price, category_id, created_at, updated_at)
3. **categories**: Product categories (id, name, description, created_at)

## PGSync Configuration

PGSync is configured to sync all three tables to OpenSearch with the following transformations:
- `created_at` → `created_timestamp`
- `updated_at` → `updated_timestamp`

## Deployment Instructions

1. **Deploy the infrastructure:**
   ```bash
   cd iac/src
   terraform init
   terraform plan
   terraform apply
   ```

2. **Verify PostgreSQL connection:**
   ```bash
   psql -h localhost -p 5432 -U pgsync -d pgsync_db
   ```

3. **Check OpenSearch status:**
   ```bash
   curl -k https://localhost:9200/_cluster/health
   ```

4. **Monitor PGSync logs:**
   ```bash
   kubectl logs -n pgsync deployment/pgsync -f
   ```

## Testing Data Synchronization

1. **Insert test data into PostgreSQL:**
   ```sql
   INSERT INTO users (name, email) VALUES ('Test User', 'test@example.com');
   ```

2. **Verify data appears in OpenSearch:**
   ```bash
   curl -k "https://localhost:9200/pgsync/_search?pretty"
   ```

3. **View data in OpenSearch Dashboard:**
   Open http://localhost:5601 and create an index pattern for `pgsync`

## Connection Details

### PostgreSQL
- Host: localhost
- Port: 5432
- Database: pgsync_db
- Username: pgsync
- Password: pgsync123
- Admin Username: postgres
- Admin Password: postgres123

### OpenSearch
- URL: https://localhost:9200
- Dashboard: http://localhost:5601

### PGSync
- API: http://localhost:8080
- Status endpoint: http://localhost:8080/status

## Troubleshooting

1. **Check service status:**
   ```bash
   kubectl get pods -n iac
   kubectl get pods -n pgsync
   ```

2. **View service logs:**
   ```bash
   kubectl logs -n iac deployment/postgresql
   kubectl logs -n iac deployment/opensearch
   kubectl logs -n pgsync deployment/pgsync
   ```

3. **Restart PGSync if needed:**
   ```bash
   kubectl rollout restart deployment/pgsync -n pgsync
   ```

## Security Notes

- This setup uses basic authentication and is intended for development/testing
- For production, implement proper SSL certificates and authentication
- Consider using Kubernetes secrets for sensitive configuration
