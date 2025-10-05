# Linux-Bash-Scripts

---

# 🐧 Linux System Administration Scripts

Two powerful Bash scripts for log analysis and system monitoring.

## 📦 Log Analyzer 

### 🔍 `log_analyzer.sh` 

**Purpose**: The log_analyzer.sh script is designed to analyze log files and generate a detailed report of system or application activity based on common log levels (ERROR, WARNING, INFO).  

**Features**:

✔ Checks if a log file is provided and exists

✔ Analyzes the log file for:

          Number of ERROR, WARNING, and INFO messages    
          Top 5 most common error messages       
          Timestamp of the first and last error        
          Error frequency grouped by hour of the day        

✔ Visually displays a histogram of error frequency using ASCII bar graphs

✔ Saves the entire report to a timestamped .txt file 

✅ How to Use

Save this script as log_analyzer.sh.    

Make it executable:
          
          chmod +x log_analyzer.sh    

Run it with your log file:

          ./log_analyzer.sh  

## 🛠️ Requirements

    Linux environment (Ubuntu, Debian, etc.)

    Uses grep, sed, awk, stat, date, cut, head, tail, sort, uniq, printf, tee etc.


---

## 📦 System health Monitor

### 📊 `system_health_monitor.sh`  

**Purpose**: The health_monitor.sh script provides a live, terminal-based dashboard that displays real-time system health metrics every few seconds.

**Features**:

Continuously displays system stats (auto-refreshes every 3 seconds)

Shows:

✔  Hostname, date, uptime

✔  CPU usage with process breakdown and alert level

✔  Memory usage with breakdown (free, cache, buffers)

✔  Disk usage of key mounts with alert thresholds

✔  Network usage (in/out speed on eth0)

✔  Load averages (1, 5, 15 minutes)

✔ Recent alerts if thresholds are exceeded (simulated or real)

Uses ASCII bars and color-coded status: [OK], [WARNING], [CRITICAL] 

✅ How to Run

Save the script:          

          nano system_monitor.sh
          # Paste the script

Make it executable:          

          chmod +x system_monitor.sh

Run it:          

          ./system_monitor.sh

## 🛠️ Requirements

    Linux environment (Ubuntu, Debian, etc.)

    Network interface must be eth0 (adjust if needed)

    Uses top, df, free, ps, /proc, etc.

---

## 📄 License

This project is released under the MIT License.

---

## 👤 Author

*Wasiq Mahmood*  
📬 wasiqmahmood93@gmail.com
