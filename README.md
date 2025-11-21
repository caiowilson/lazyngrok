How to use
	•	One-off full run (files + logs + pause):
     ./ngrok_get_ip.sh
 	•	Just get the first public URL (for copy/paste or scripting):
     ./ngrok_get_ip.sh --url-only
 	•	Run continuously, refreshing every 10 seconds:
     ./ngrok_get_ip.sh --watch 10
 	•	Auto-open the first URL in your browser (single run):
     ./ngrok_get_ip.sh --open
 	•	Quiet, script-friendly URL output:
     ./ngrok_get_ip.sh --quiet --url-only


 idea stolen shamelessly from https://github.com/Fathraganteng
