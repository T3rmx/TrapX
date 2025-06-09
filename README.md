
# ⚠️ Fake Update Exploit Script

A **Bash automation script** that sets up a phishing environment with a **fake software update page**, generates a **Metasploit payload**, and automatically starts listeners to catch sessions. It's integrated with Telegram to notify you of activities.

> **⚠️ Educational Use Only!**
> This tool is intended for **ethical hacking**, **cybersecurity training**, and **authorized penetration testing** in **controlled environments**.  
> **Do not** use it against systems or users without explicit consent.

---

## 📁 Features

- 🎯 **Payload Generator** using `msfvenom`
- 🌐 **Fake Update Web Page** hosted via Python HTTP server
- 📡 **Metasploit Handler** launches automatically
- 📩 **Telegram Bot Integration** for alerts
- 🧾 **Logging**: sessions, actions, and HTTP/MSF logs
- 🔒 **Auto-cleanup** on exit (`SIGINT`, `SIGTERM`)

---

## ⚙️ Requirements

Ensure the following tools are installed:

| Dependency       | Purpose                        |
|------------------|--------------------------------|
| `beef-xss`       | XSS attack support (optional)  |
| `msfconsole`     | Handle incoming sessions       |
| `msfvenom`       | Generate the payload           |
| `python3`        | Serve fake webpage             |
| `curl` + `jq`    | Telegram API & IP checks       |

Install via:

```bash
sudo apt install metasploit-framework curl jq python3
````

---

## 🚀 Usage

1. **Run the script**:

```bash
chmod +x script.sh
./script.sh
```

2. **On first run**, you'll be prompted to enter your:

   * Telegram Bot Token
   * Telegram Chat ID

   These will be saved to `config.cfg`.

3. **Select Payload**:
   Choose from:

   * `windows/meterpreter/reverse_tcp`
   * `python/meterpreter/reverse_tcp`
   * `android/meterpreter/reverse_tcp`

4. **Enter LPORT**:
   Choose the port Metasploit should listen on (e.g., `4444`).

5. The script will:

   * Generate a payload (`chrome_update_2025.exe`)
   * Create a phishing page (`web/update.html`)
   * Launch the server at:
     `http://<your_ip>:8000/web/update.html`

6. When the victim clicks **Download Update**, the payload is downloaded and executed (if run by victim), and you'll receive a session in Metasploit.

---

## 📂 Directory Structure

```bash
├── config.cfg           # Telegram config
├── logs/
│   ├── sessions.log     # Captured sessions
│   └── activity.log     # Script activities
├── payload/
│   └── chrome_update_2025.exe
├── web/
│   └── update.html      # Fake update landing page
-----
```

---

## 🛑 Warnings

* This script is **dangerous** if misused.
* DO NOT deploy this on public networks or target unauthorized users.
* You are fully responsible for how this tool is used.

---

## 🧠 Notes

* The payload is generated with `x86/shikata_ga_nai` encoder, 3 iterations.
* HTTP server is launched on **port 8000** by default.
* The Metasploit handler listens on all interfaces (`0.0.0.0`).

---

## 📬 Telegram Notifications (Optional)

You'll be prompted to input:

* `TELEGRAM_TOKEN` – from [@BotFather](https://t.me/BotFather)
* `CHAT_ID` – get via `curl`:

```bash
curl -s "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates" | jq
```

Replace `<YOUR_BOT_TOKEN>` and look for your ID in the JSON.

---

## 📜 License

This script is open-source and intended for **educational** purposes under the [MIT License](https://opensource.org/licenses/MIT).

---

## 🙋 Author

**Script by:** T3rmx

**Maintained by:** Red Team Enthusiasts

**Contact:** Telegram:@vvsks

---

