# event-stack

**event-stack** is a modern local development environment that unifies a **Laravel web app** and a **Moodle LMS** inside a single Docker + DDEV workspace — powered by **PostgreSQL**, **Mailpit**, and full automation via shell scripts.

It’s designed for rapid development, integration, and testing between Moodle plugins and Laravel-based APIs, dashboards, or automation tools.

---

## ⚙️ Features

- 🐳 **DDEV + Docker** – containerized and reproducible
- 🐘 **PostgreSQL 15** – shared database backend
- 📬 **Mailpit** – local email testing
- 🧱 **Laravel (PHP 8.3)** – modern app + API layer
- 🎓 **Moodle 5.1 (PHP 8.3)** – LMS core for learning functionality
- ⚡ **One-command setup** – fully automated with `setup.sh`
- 🧹 **Safe cleanup** – factory reset via `cleanup.sh` (preserves repo + scripts)

---

## 🚀 Quick Start

Set up everything — Laravel + Moodle — in just a few minutes.

```bash
# 1️⃣ Clone the repository
git clone https://github.com/YOURORG/event-stack.git
cd event-stack

# 2️⃣ Run the setup script (creates + starts everything)
./scripts/setup.sh