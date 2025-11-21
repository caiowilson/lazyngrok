    #!/usr/bin/env bash
    # Ngrok - GetIPFromAPP (Terminal)
    
    set -euo pipefail
    
    # Colors (optional)
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
    
    OUTPUT_TXT="output.txt"
    GENERATED_TXT="generated.txt"
    NGROK_API_URL="http://localhost:4040/api/tunnels"
    
    # Default command to start ngrok (EDIT THIS IF YOU WANT)
    # Example: ngrok http 8080
    NGROK_START_CMD=(ngrok http 80)
    
    # Mode flags
    HAS_JQ=0
    URL_ONLY=0
    WATCH_INTERVAL=0
    AUTO_OPEN=0
    QUIET=0
    DEST_DIR="${PWD}"
    START_NGROK=0
    
    log() {
        if [[ "${QUIET}" -eq 0 ]]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
        fi
    }
    
    usage() {
        cat <<EOF
    Usage: $0 [OPTIONS] [DEST_DIR]
    
    Fetch Ngrok tunnel data from:
        ${NGROK_API_URL}
    
    Options:
        -h, --help        Show this help and exit
        --start-ngrok     Start ngrok automatically (default: 'ngrok http 80')
        --url-only        Print first public URL and exit (requires jq)
        --watch N         Repeat every N seconds (no url-only in this mode)
        --open            Open first public URL in default browser (macOS)
        --quiet           Minimal output (no logs/header)
    
    DEST_DIR (optional, default: current directory):
        Directory where these files are written:
          - ip_data.html         (same content as ${OUTPUT_TXT})
          - generated_time.html  (same content as ${GENERATED_TXT})
          - ngrok_urls.txt       (list of public URLs, if jq is installed)
    
    Also created in the current working directory:
          - ${OUTPUT_TXT}        (raw JSON data)
          - ${GENERATED_TXT}     (generation timestamp)
    
    Default ngrok start command:
          ${NGROK_START_CMD[*]}
    EOF
    }
    
    ensure_dependencies() {
        if ! command -v curl >/dev/null 2>&1; then
            echo "Error: 'curl' is required but not installed."
            exit 1
        fi
    
        if command -v jq >/dev/null 2>&1; then
            HAS_JQ=1
        else
            HAS_JQ=0
            log "Warning: 'jq' not found. Will not extract public URLs."
        fi
    
        if [[ "${START_NGROK}" -eq 1 ]]; then
            if ! command -v ngrok >/dev/null 2>&1; then
                echo "Error: 'ngrok' is required for --start-ngrok but not found in PATH."
                exit 1
            fi
        fi
    }
    
    parse_args() {
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -h|--help)
                    usage
                    exit 0
                    ;;
                --start-ngrok)
                    START_NGROK=1
                    shift
                    ;;
                --url-only)
                    URL_ONLY=1
                    shift
                    ;;
                --watch)
                    if [[ $# -lt 2 ]]; then
                        echo "Error: --watch requires an interval in seconds."
                        exit 1
                    fi
                    WATCH_INTERVAL="$2"
                    shift 2
                    ;;
                --open)
                    AUTO_OPEN=1
                    shift
                    ;;
                --quiet)
                    QUIET=1
                    shift
                    ;;
                *)
                    # First non-flag argument is DEST_DIR
                    DEST_DIR="$1"
                    shift
                    ;;
            esac
        done
    
        if [[ "${URL_ONLY}" -eq 1 && "${WATCH_INTERVAL}" -gt 0 ]]; then
            echo "Error: --url-only and --watch cannot be used together."
            exit 1
        fi
    }
    
    print_header() {
        if [[ "${QUIET}" -ne 0 ]]; then
            return
        fi
    
        # Set terminal title (optional)
        printf "\033]0;Ngrok - GetIPFromAPP (Terminal)\007"
    
        echo -e "${CYAN}Ngrok - GetIPFromAPP${NC}"
        echo "======================"
        echo "-This tool gets your connect address via Ngrok to server."
        echo "-And saves to file output.txt; from this file a new file is made via IP address."
        echo
        echo "-Is FREE for everyone who has the same problem with NGROK and must copy and paste new IP every time."
        echo "-This tool is still early access and can be broken."
        echo
        echo "-LOG: $(date '+%Y-%m-%d %H:%M:%S') in folder $(pwd) via $USER"
        echo
    }
    
    cleanup_old_files() {
        log "Cleaning old files (${OUTPUT_TXT}, ${GENERATED_TXT}) if they exist..."
        rm -f "${OUTPUT_TXT}" "${GENERATED_TXT}"
        if [[ "${QUIET}" -eq 0 ]]; then
            echo
        fi
    }
    
    is_ngrok_running() {
        ps aux | grep "[n]grok" >/dev/null 2>&1
    }
    
    wait_for_ngrok_api() {
        # Wait up to ~10 seconds for the API to come up
        for i in {1..10}; do
            if curl -fsS "${NGROK_API_URL}" >/dev/null 2>&1; then
                log "Ngrok API is up."
                return 0
            fi
            log "Waiting for Ngrok API... (${i}/10)"
            sleep 1
        done
        echo "Error: Ngrok API did not become ready on ${NGROK_API_URL}."
        exit 1
    }
    
    start_ngrok_if_requested() {
        if [[ "${START_NGROK}" -ne 1 ]]; then
            return
        fi
    
        if is_ngrok_running; then
            log "Ngrok is already running; not starting another instance."
            wait_for_ngrok_api
            return
        fi
    
        log "Starting ngrok: ${NGROK_START_CMD[*]}"
        # Start in the background, log output to ngrok.log
        nohup "${NGROK_START_CMD[@]}" > ngrok.log 2>&1 & disown || {
            echo "Error: failed to start ngrok."
            exit 1
        }
    
        wait_for_ngrok_api
    }
    
    check_ngrok() {
        log "Checking if ngrok is running..."
        if is_ngrok_running; then
            log "Ngrok process detected."
        else
            log "No ngrok process detected. The API call may fail if ngrok is not running."
        fi
        if [[ "${QUIET}" -eq 0 ]]; then
            echo
        fi
    }
    
    fetch_tunnels() {
        log "Fetching data from Ngrok API: ${NGROK_API_URL}"
    
        # Write JSON directly to OUTPUT_TXT, fail clearly if API is unreachable
        if ! curl -fsS "${NGROK_API_URL}" > "${OUTPUT_TXT}"; then
            echo
            echo "Error: Could not reach Ngrok API at ${NGROK_API_URL}."
            echo "Make sure ngrok is running and its web interface (on port 4040) is enabled."
            exit 1
        fi
    
        echo "Generated information: $(date '+%Y-%m-%d %H:%M:%S')" > "${GENERATED_TXT}"
        log "Data saved to ${OUTPUT_TXT}, timestamp saved to ${GENERATED_TXT}."
        if [[ "${QUIET}" -eq 0 ]]; then
            echo
        fi
    }
    
    get_first_url() {
        if [[ "${HAS_JQ}" -ne 1 ]]; then
            echo ""
            return
        fi
        jq -r '.tunnels[0].public_url // empty' "${OUTPUT_TXT}" 2>/dev/null || echo ""
    }
    
    print_first_url_and_exit() {
        if [[ "${HAS_JQ}" -ne 1 ]]; then
            echo "Error: --url-only requires 'jq' to be installed."
            exit 1
        fi
    
        first_url=$(get_first_url)
        if [[ -z "${first_url}" ]]; then
            echo "No public URL found."
            exit 1
        fi
    
        echo "${first_url}"
        exit 0
    }
    
    extract_urls_if_possible() {
        if [[ "${HAS_JQ}" -ne 1 ]]; then
            return
        fi
    
        log "Extracting public URLs using jq..."
        local urls
        urls=$(jq -r '.tunnels[].public_url' "${OUTPUT_TXT}" 2>/dev/null || true)
    
        if [[ -z "${urls}" ]]; then
            log "No public URLs found in JSON."
            return
        fi
    
        if [[ "${QUIET}" -eq 0 ]]; then
            echo
            echo "Public URLs found:"
            echo "${urls}"
        fi
    
        local urls_file="${DEST_DIR}/ngrok_urls.txt"
        mkdir -p "${DEST_DIR}"
        printf "%s\n" "${urls}" > "${urls_file}"
        log "Public URLs written to ${urls_file}."
        if [[ "${QUIET}" -eq 0 ]]; then
            echo
        fi
    }
    
    copy_to_dest_dir() {
        log "Copying files to directory: ${DEST_DIR}"
        mkdir -p "${DEST_DIR}"
    
        cp "${OUTPUT_TXT}"    "${DEST_DIR}/ip_data.html"
        cp "${GENERATED_TXT}" "${DEST_DIR}/generated_time.html"
    
        log "Copied:"
        log "  ${OUTPUT_TXT}    -> ${DEST_DIR}/ip_data.html"
        log "  ${GENERATED_TXT} -> ${DEST_DIR}/generated_time.html"
        if [[ "${QUIET}" -eq 0 ]]; then
            echo
        fi
    }
    
    open_first_url_in_browser() {
        if [[ "${AUTO_OPEN}" -ne 1 ]]; then
            return
        fi
        if [[ "${HAS_JQ}" -ne 1 ]]; then
            log "Cannot auto-open URL: 'jq' is not installed."
            return
        fi
    
        first_url=$(get_first_url)
        if [[ -z "${first_url}" ]]; then
            log "Cannot auto-open URL: no public URL found."
            return
        fi
    
        log "Opening ${first_url} in your default browser..."
        open "${first_url}" >/dev/null 2>&1 || true
    }
    
    main_loop_once() {
        cleanup_old_files
        check_ngrok
        fetch_tunnels
        extract_urls_if_possible
        copy_to_dest_dir
        open_first_url_in_browser
    }
    
    main() {
        parse_args "$@"
        ensure_dependencies
        print_header
        start_ngrok_if_requested
    
        # Simple url-only mode: fetch once, print URL, exit
        if [[ "${URL_ONLY}" -eq 1 ]]; then
            cleanup_old_files
            check_ngrok
            fetch_tunnels
            print_first_url_and_exit
        fi
    
        # Watch mode: repeat every WATCH_INTERVAL seconds
        if [[ "${WATCH_INTERVAL}" -gt 0 ]]; then
            while true; do
                main_loop_once
                log "Sleeping ${WATCH_INTERVAL}s..."
                sleep "${WATCH_INTERVAL}"
                if [[ "${QUIET}" -eq 0 ]]; then
                    echo
                fi
            done
        else
            # Single run
            main_loop_once
            if [[ "${QUIET}" -eq 0 ]]; then
                echo -e "${GREEN}Done.${NC}"
                echo "Output directory: ${DEST_DIR}"
                read -r -p "Press Enter to exit..."
            fi
        fi
    }
    
    main "$@"
