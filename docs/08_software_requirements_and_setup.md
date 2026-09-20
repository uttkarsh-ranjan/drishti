# Software Requirements & Ubuntu Setup Guide

## 1. Overview
This document outlines the software dependencies required to develop and run the Drishti platform locally. The installation instructions provided are tailored for **Ubuntu Linux**.

---

## 2. Docker Engine & Docker Compose
* **Purpose**: Used to containerize and easily run complex backend infrastructure without polluting your host machine. This includes running PostgreSQL + PostGIS (database), Redis (message broker for Celery), and MediaMTX (RTSP streaming server).

### Installation (Ubuntu)
Run the following commands to install Docker and Docker Compose using the official repository:

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker Engine and Compose
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# (Optional) Allow running docker without sudo
sudo usermod -aG docker $USER
newgrp docker
```

---

## 3. Python 3.10+
* **Purpose**: Required to run the Flask API Gateway, the Celery asynchronous task workers, and the AI Pipeline (PyTorch, OpenCV). 

### Installation (Ubuntu)
Ubuntu usually comes with Python 3 pre-installed. You can verify and install the required virtual environment tools:

```bash
# Update packages
sudo apt update

# Install Python 3, pip, and venv
sudo apt install python3 python3-pip python3-venv python3-dev

# Verify installation
python3 --version
```

---

## 4. Node.js (v18+) & npm
* **Purpose**: Required to build, run, and develop the React.js + TypeScript Web Dashboard.

### Installation (Ubuntu)
It is recommended to install Node.js using NVM (Node Version Manager) to easily manage versions:

```bash
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load NVM (or restart your terminal)
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js (v20 LTS is recommended)
nvm install 20

# Verify installation
node -v
npm -v
```

---

## 5. Flutter SDK
* **Purpose**: The framework used to develop the cross-platform mobile application for PMU Inspectors.

### Installation (Ubuntu)
```bash
# Install dependencies
sudo apt-get install curl git unzip xz-utils zip libglu1-mesa

# Download Flutter SDK (replace with latest version link if needed)
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz

# Extract to an installation directory (e.g., ~/development)
mkdir -p ~/development
tar xf flutter_linux_3.24.0-stable.tar.xz -C ~/development/

# Add flutter to your PATH (Add this line to your ~/.bashrc or ~/.zshrc)
export PATH="$PATH:$HOME/development/flutter/bin"

# Reload shell
source ~/.bashrc
```

---

## 6. Android Studio
* **Purpose**: Required by Flutter. Provides the Android SDK, build toolchain, and Android Emulator necessary to compile and test the mobile application locally on Linux.

### Installation (Ubuntu)
```bash
# Install Java Development Kit (Required for Android)
sudo apt install openjdk-17-jdk

# Download Android Studio via Snap
sudo snap install android-studio --classic
```

**Post-Installation Steps for Flutter:**
1. Open Android Studio and complete the initial setup wizard to download the Android SDK.
2. Open your terminal and run the flutter doctor command to accept licenses and verify the setup:
```bash
flutter doctor --android-licenses
flutter doctor
```
