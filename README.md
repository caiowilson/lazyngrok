    Usage: ngrok_get_ip.sh [OPTIONS] [DEST_DIR]
    
    Fetch Ngrok tunnel data from:
        http://localhost:4040/api/tunnels
    
    Options:
        -h, --help        Show this help and exit
        --start-ngrok     Start ngrok automatically (default: 'ngrok http 80')
        --url-only        Print first public URL and exit (requires jq)
        --watch N         Repeat every N seconds (no --url-only in this mode)
        --open            Open first public URL in default browser (macOS)
        --quiet           Minimal output (no logs/header)
    
    DEST_DIR (optional, default: current directory):
        Directory where these files are written:
          - ip_data.html         (same content as output.txt)
          - generated_time.html  (same content as generated.txt)
          - ngrok_urls.txt       (list of public URLs, if jq is installed)
    
    Files created in the current working directory:
          - output.txt           (raw JSON data from Ngrok API)
          - generated.txt        (generation timestamp)
    
    Default ngrok start command (used with --start-ngrok):
          ngrok http 80
    
    Examples:
        # Single run: use existing ngrok, generate files, pause at the end
        ngrok_get_ip.sh
    
        # Start ngrok (http 80), generate files, pause
        ngrok_get_ip.sh --start-ngrok
    
        # Start ngrok and print only the first public URL, then exit
        ngrok_get_ip.sh --start-ngrok --url-only
    
        # Quiet mode for scripting: only print the URL
        ngrok_get_ip.sh --quiet --url-only
    
        # Watch mode: refresh data and files every 10 seconds
        ngrok_get_ip.sh --watch 10
    
        # Start ngrok, auto-open the URL in the browser, generate files
        ngrok_get_ip.sh --start-ngrok --open



 idea shamelessly stolen from @Fathraganteng
