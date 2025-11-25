# SymfonyCon 2025 - Scaling PHP Systems

This project demonstrates a scalable Symfony CQRS application with Redis and DB projections, Docker Compose, and k6 load
testing. All common tasks are managed via the Makefile.

## Setup

Before running this project, ensure you have the following dependencies installed:

Check missing dependencies.

```bash
./test-system.sh
```

### Required Dependencies

1. **Docker & Docker Compose**
    - [Docker Desktop](https://www.docker.com/products/docker-desktop/) (includes Docker Compose)
    - Or install separately: [Docker](https://docs.docker.com/get-docker/)
      and [Docker Compose](https://docs.docker.com/compose/install/)

2. **Make**
    - **macOS**: Usually pre-installed, or install via Homebrew: `brew install make`
    - **Linux**: Install via package manager:
        - Ubuntu/Debian: `sudo apt-get install make`
        - CentOS/RHEL: `sudo yum install make`
        - Fedora: `sudo dnf install make`

3. **K6 (Load Testing Tool)**
    - **macOS**: `brew install k6`
    - **Linux**:
        - Ubuntu/Debian: `sudo gpg -k`
      ```bash
      sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
      echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
      sudo apt-get update
      sudo apt-get install k6
      ```
        - CentOS/RHEL/Fedora: `sudo yum install k6` or `sudo dnf install k6`

### Verify Installation

Run the test script to verify all dependencies are installed:

```bash
./test-system.sh
```

This will check for Docker, Docker Compose, Make, and K6 and report their status.

### Docker Images Setup

Before starting the application, you need to pull the required Docker images. You can do this in two ways:

**Pull all images at once**

```bash
make pull-docker
```

This ensures all required Docker images are available locally before starting the services.

## Quick Start

1. **Build and start all services:**

```bash
make up
```

2. **Set up the database and seed data:**

```bash
make migrate
make seed
```

Go to http://localhost:8088

### opcache introduction

```
make up-opcache-dashboard
```

open - http://localhost:42042/opcache/status

https://www.php.net/manual/en/opcache.configuration.php#:~:text=on%20all%20architectures.-,opcache.max_accelerated_files,-int

```
find . -type f -name "*.php" | wc -l

opcache.max_accelerated_files=16087

```

### show fpm and opcache dashboard GUI

show fpm status page - http://localhost:8088/fpm-status

```
fpm.conf - pm.status_path = /fpm-status
aa-nginx.conf - location ~ ^/fpm-status$ {

```

**fpm-exporter**

```
make up-exporter
make ps | grep exporter
```

Go to http://localhost:9253/metrics

```
make up-prometheus
make ps | grep prom
```

Go to http://localhost:9090/targets?search=

```
make up-grafana
make ps | grep grafana
```

### Show target prom sources

http://localhost:9090/targets?search=

### view grafana dashboard

open http://localhost:3000
username: croatia
password: croatia

### show grafana fpm/opcache dashboard

```bash
make benchmark-product-random-fpm
```

Output:
![PHP-FPM Benchmark Results](docs/images/benchmark-product-random-fpm.png)

see file inside k6/report-UTC-xxxxxxx.html
> i.e: k6/report-product-by-id-random-8088-2025-11-25T10-45-06.548Z.html

Check grafana output - http://localhost:3000

See fpm active processes. change to 5m (on left side)
http://localhost:3000/d/phpfpm-performance/php-fpm-performance-dashboard?orgId=1&from=now-5m&to=now&timezone=browser&var-datasource=PBFA97CFB590B2093&var-pool=www&refresh=5s

## PHP-FPM Performance Monitoring & Optimization

### Accessing FPM Status & Metrics

**FPM Status Page:**
- URL: http://localhost:8088/fpm-status
- Shows real-time process states, active/idle workers, queue length
- Configured in `fpm.conf` with `pm.status_path = /fpm-status`

**Prometheus Metrics:**
- URL: http://localhost:9253/metrics (via php-fpm-exporter)
- Scraped by Prometheus for historical data and alerting
- Visualized in Grafana dashboards

### Right-Sizing PHP-FPM Pool Configuration

PHP-FPM pool sizing is critical for optimal performance. You need to balance:
- Available RAM
- Expected concurrent requests
- Per-request memory usage
- Response time requirements

**Configuration Logic:**

![FPM Pool Sizing](docs/fpm-pool-sizing.png)

**Formula for `pm.max_children`:**
```
pm.max_children = (Total Available RAM - RAM for other services) / Average PHP Process Memory
```

**Example Calculation:**
```
Server RAM: 4GB (4096 MB)
System + MySQL: 1GB (1024 MB)
Average PHP process: 50 MB

pm.max_children = (4096 - 1024) / 50 = 61 processes
```

**FPM Calculator Tool:**

Use the interactive calculator at https://spot13.com/pmcalculator/ to determine optimal settings:

![FPM Calculator](docs/fpm-calculator.png)

### Key Configuration Settings

PHP-FPM uses a process manager to handle incoming requests efficiently. The configuration directly affects what you see in system monitoring tools like `htop`.

```ini
pm = dynamic                    # Process manager type (static, dynamic, ondemand)
pm.max_children = 50            # Maximum number of child processes
pm.start_servers = 5            # Number of children created on startup
pm.min_spare_servers = 5        # Minimum idle processes
pm.max_spare_servers = 35       # Maximum idle processes
pm.max_requests = 500           # Requests before process restart (helps with memory leaks)
```

**Process Manager Types:**
- `static` - Fixed number of processes (best for consistent load)
- `dynamic` - Scales between min/max spare servers (good for variable load)
- `ondemand` - Creates processes on demand (best for low/intermittent traffic)

**Important:** `pm.start_servers = 5` means you will see **5 child processes** in `htop` when the container starts, plus 1 master process (total 6 PHP-FPM processes).

### Process Hierarchy and Behavior

When you run `htop` or `ps aux | grep php-fpm`, you'll see:

```
1 × php-fpm: master process (manages child processes)
5 × php-fpm: pool www (child processes handling requests)
```

**Process Roles:**
- **Master Process** - Manages child processes, handles signals, doesn't serve requests
- **Child Processes** - Handle actual HTTP requests from nginx/web server
- **Dynamic Scaling** - Processes spawn/die based on load (between `min_spare_servers` and `max_spare_servers`)

**Process States:**
- `Idle` - Waiting for requests
- `Running` - Actively processing a request
- `Finishing` - Completing request cleanup
- `Reading headers` - Parsing request headers
- `Ending` - Process is shutting down

## Monitoring Commands (Run Inside Container During k6 Tests)

### Check Real-Time Process Usage

**List processes sorted by memory (RSS):**
```bash
ps -ylC php-fpm --sort:rss
```

**Watch process states in real-time:**
```bash
watch -n 1 'ps aux | grep php-fpm'
```

**Count active vs idle processes:**
```bash
curl -s http://localhost:8088/fpm-status | grep -E "active|idle"
```

### Calculate Process Memory

**Average memory per process (in MB):**
```bash
ps --no-headers -o "rss,cmd" -C php-fpm | awk '{ sum+=$1} END { print sum/NR/1024 }'
```

**Total memory usage by all PHP-FPM processes:**
```bash
ps --no-headers -o "rss,cmd" -C php-fpm | awk '{ sum+=$1 } END { print sum/1024 " MB" }'
```

**Memory usage per individual process:**
```bash
ps -o pid,rss,cmd -C php-fpm | awk 'NR>1 {print $1, $2/1024 " MB", $3}'
```

### Advanced Monitoring

**Get CPU usage by PHP-FPM:**
```bash
ps -C php-fpm -o %cpu,pid,cmd --no-headers
```

**Find the most memory-intensive PHP-FPM process:**
```bash
ps --no-headers -o "rss,pid,cmd" -C php-fpm | sort -rn | head -5
```

**Count processes by state:**
```bash
# Requires status page to be enabled
curl -s http://localhost:8088/fpm-status?full | grep -c "state: Idle"
curl -s http://localhost:8088/fpm-status?full | grep -c "state: Running"
```

### Understanding the Output

**RSS (Resident Set Size):**
- Physical memory used by the process
- Shown in KB by default
- Divide by 1024 for MB

**VSZ (Virtual Memory Size):**
- Total virtual memory allocated
- Usually much larger than RSS
- Includes shared libraries

**Example Output Interpretation:**
```bash
$ ps -ylC php-fpm --sort:rss
  RSS    PID  CMD
52340  12345  php-fpm: master process
48512  12346  php-fpm: pool www
50240  12347  php-fpm: pool www
```

This shows:
- Master process using ~51 MB
- Child processes using ~47-49 MB each
- Total usage: ~150 MB for 3 processes

### Composer Autoload Optimization

For optimal performance, this project uses Composer autoload optimizations configured in `composer.json`:

```json
{
  "config": {
    "optimize-autoloader": true,
    "classmap-authoritative": true
  }
}
```

**Performance Impact:**

- `optimize-autoloader`: ~10-15% faster autoloading (converts PSR-0/PSR-4 to classmap)
- `apcu-autoloader`: ~50-70% faster (requires APCu extension)
- `classmap-authoritative`: Set to `false` for development, `true` for production only

**Reference:** See the
official [Symfony Performance Documentation](https://symfony.com/doc/current/performance.html#optimize-composer-autoloader)
for detailed autoloader optimization guidelines and best practices.

## Web Interfaces & Dashboards

| Service               | URL                           | Description                           |
|-----------------------|-------------------------------|---------------------------------------|
| FPM App               | http://localhost:8088         | Main Symfony app (FPM)                |
| Franken               | http://localhost:8080         | FrankenPHP (HTTP, regular mode)       |
| Franken Worker        | http://localhost:8081         | FrankenPHP Worker (HTTP, optimized)   |
| Grafana               | http://localhost:3000         | Metrics dashboard (admin/admin)       |
| Prometheus            | http://localhost:9090         | Prometheus metrics                    |
| Opcache Dashboard     | http://localhost:42042        | PHP Opcache dashboard                 |
| Opcache Metrics (FPM) | http://localhost:8088/metrics | PHP Opcache metrics via FPM app       |
| Franken Metrics       | http://localhost:2019/metrics | Caddy/FrankenPHP metrics (non-worker) |
| Worker Metrics        | http://localhost:2020/metrics | Caddy/FrankenPHP metrics (worker)     |

## Grafana Dashboard

A detailed PHP-FPM and OPcache monitoring dashboard is available in Grafana. It includes:

- PHP-FPM health, queue, and process metrics
- Request rate, duration, and memory usage
- OPcache hit ratio, memory, and script cache stats
- JIT and interned strings monitoring
- Alerts and color-coded panels for quick health checks

**See [`grafana-dashboard.md`](grafana-dashboard.md) for a full description of all panels and dashboard features.**

## FrankenPHP Configuration

This project uses FrankenPHP (a modern PHP runtime built on Caddy) with two different configurations for performance
comparison and monitoring.

**See [`frankenphp.md`](frankenphp.md) for complete FrankenPHP documentation including:**

- Service configuration and differences
- Auto-reload (file watching) setup
- Caddy configuration and environment variables
- Performance testing and monitoring
- Troubleshooting guide
- Resource optimization guidelines