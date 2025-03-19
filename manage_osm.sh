#!/bin/bash

# Define variables
PROJECT_DIR="$(pwd)"
OSM_URL="https://download.geofabrik.de/asia/india/southern-zone-latest.osm.pbf"
OUTPUT_FILE="osm-map.pbf"
CRON_JOB="0 0 * * * $PROJECT_DIR/manage_osm.sh update"
LOG_FILE="$PROJECT_DIR/manage_osm.log"

# Create osm-data directory if it doesn't exist
mkdir -p osm-data

# Function to log messages
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >>"$LOG_FILE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Function to display help
show_help() {
  echo "Usage: $0 {start|stop|status|update|setup|help}"
  echo
  echo "Commands:"
  echo "  start       Start Docker containers."
  echo "  stop        Stop Docker containers."
  echo "  status      Check Docker container status."
  echo "  update      Update OSM data from the specified URL."
  echo "  setup       Set up the environment and cron job."
  echo "  help        Display this help message."
}

# Function to start Docker containers
start_containers() {
  log "Starting Docker containers..."
  docker compose up -d
  log "Docker containers started."
}

# Function to stop Docker containers
stop_containers() {
  log "Stopping Docker containers..."
  docker compose down
  log "Docker containers stopped."
}

# Function to check Docker container status
check_status() {
  log "Checking Docker container status..."
  docker ps
}

# Function to update OSM data
update_osm() {
  local url=${1:-$OSM_URL} # Use provided URL or default
  local output_path="./osm-data/$OUTPUT_FILE"

  log "Updating OSM data from: $url"

  # Stop containers if running
  stop_containers

  # Download the OSM file
  log "Downloading OSM file..."
  if curl -L -o "$output_path" "$url"; then
    log "Downloaded OSM file to: $output_path"
  else
    log "Error downloading OSM file from $url"
    exit 1
  fi

  # Start Docker containers
  start_containers
}

# Function to set up the environment and cron job
setup_environment() {
  log "Setting up environment..."

  # Create or update the osm-data directory
  mkdir -p osm-data

  # Download initial OSM data if not exists
  if [ ! -f "./osm-data/$OUTPUT_FILE" ]; then
    log "Downloading initial OSM data..."
    update_osm
  fi

  # Set up cron job
  (
    crontab -l 2>/dev/null | grep -v "$PROJECT_DIR/manage_osm.sh"
    echo "$CRON_JOB"
  ) | crontab -
  log "Cron job set to update OSM data daily at midnight."

  log "Setup complete. You can now start the services."
}

# Make script executable
chmod +x "$0"

# Main script logic
case "$1" in
start)
  start_containers
  ;;
stop)
  stop_containers
  ;;
status)
  check_status
  ;;
update)
  update_osm "$2"
  ;;
setup)
  setup_environment
  ;;
help)
  show_help
  ;;
*)
  show_help
  exit 1
  ;;
esac
