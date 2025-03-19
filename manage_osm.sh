#!/bin/bash

# Define variables
PROJECT_DIR="$(pwd)"
OSM_URL="https://download.geofabrik.de/europe/southeast-latest.osm.pbf"
PBF_FILE="southeast-latest.osm.pbf"
CRON_JOB="0 0 * * * $PROJECT_DIR/manage_osm.sh update"
LOG_FILE="$PROJECT_DIR/manage_osm.log"

# Create osm-data directory if it doesn't exist
mkdir -p osm-data

# Function to log messages
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >>"$LOG_FILE"
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
  docker-compose up -d
  log "Docker containers started."
}

# Function to stop Docker containers
stop_containers() {
  log "Stopping Docker containers..."
  docker-compose down
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
  log "Updating OSM data from: $url"
  output_path="./osm-data/$(basename "$url")"

  # Download the OSM file
  if [ ! -f "$output_path" ]; then
    log "Downloading OSM file..."
    if curl -o "$output_path" "$url"; then
      log "Downloaded OSM file: $output_path"
    else
      log "Error downloading OSM file from $url"
      exit 1
    fi
  else
    log "Using cached file: $output_path"
  fi

  # Set the PBF_FILE environment variable and start Docker containers
  export PBF_FILE="$(basename "$output_path")"
  start_containers
}

# Function to set up the environment and cron job
setup_environment() {
  # Set up cron job
  (
    crontab -l 2>/dev/null
    echo "$CRON_JOB"
  ) | crontab -
  log "Cron job set to update OSM data daily at midnight."
}

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
  echo "Invalid option. Use 'help' for usage information."
  exit 1
  ;;
esac
