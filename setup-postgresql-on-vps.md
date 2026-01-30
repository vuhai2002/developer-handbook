# How to Setup PostgreSQL on a VPS

This guide helps you install and configure PostgreSQL on an Ubuntu/Debian VPS securely, suitable for production environments.

## 📋 Table of Contents

- [1. Install PostgreSQL](#1-install-postgresql)
- [2. Create Database and User](#2-create-database-and-user)
- [3. Configure Security for Remote Access](#3-configure-security-for-remote-access)
- [4. Verify Connection](#4-verify-connection)
- [Appendix: Transaction Isolation Explained](#appendix-transaction-isolation-explained)

---

## 1. Install PostgreSQL

### Install packages

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

### Start PostgreSQL

```bash
sudo systemctl start postgresql.service
```

### ⚠️ Important: Enable auto-start on reboot

By default, PostgreSQL **does not start automatically** when VPS reboots. Run this command to enable it:

```bash
sudo systemctl enable postgresql
```

### Check status

```bash
sudo service postgresql status
```

---

## 2. Create Database and User

### Access PostgreSQL prompt

```bash
sudo -u postgres psql
```

### Create a new user

```sql
CREATE USER <username> WITH ENCRYPTED PASSWORD '<password>';
```

### Configure user settings

```sql
-- Set UTF-8 encoding for client
ALTER ROLE <username> SET client_encoding TO 'utf8';

-- Set default isolation level (see explanation below)
ALTER ROLE <username> SET default_transaction_isolation TO 'read committed';

-- Set timezone
ALTER ROLE <username> SET timezone TO 'UTC';
```

### Create database

```sql
CREATE DATABASE <database_name> 
    WITH OWNER = <username> 
    ENCODING = 'UTF8' 
    TEMPLATE = template0;
```

### Exit PostgreSQL

```sql
\q
```

> 💡 **Replace** `<username>`, `<password>`, `<database_name>` with your actual values.

---

## 3. Configure Security for Remote Access

If you need to connect to PostgreSQL remotely (e.g., from your local machine or another server), follow these steps.

### Step 0: Identify allowed IP addresses

On the machine that needs to connect (your local machine), get the public IP:

```bash
curl ifconfig.me
```

Note this IP, for example: `172.456.68.78`

### Step 1: Configure PostgreSQL listen address

Open the config file:

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

> 📝 Replace `16` with your PostgreSQL version (check with `ls /etc/postgresql/`)

Find and modify these lines:

```ini
# Only listen on localhost and server's public IP
listen_addresses = 'localhost,<SERVER_PUBLIC_IP>'
port = 5432

# REQUIRED: Enable SSL to encrypt connections
ssl = on
```

> ⚠️ **NEVER** use `listen_addresses = '*'` in production!

### Step 2: Configure pg_hba.conf (MOST IMPORTANT)

This file determines **who is allowed to connect** to PostgreSQL.

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

#### ❌ Remove or comment out dangerous lines:

```
# host all all 0.0.0.0/0 md5   <-- DANGEROUS! Allows any IP
```

#### ✅ Add rule for allowed IP (at end of file):

```
# Remote access - ONLY specific IP + require SSL
hostssl    all    all    172.456.68.78/32    scram-sha-256
```

**Explanation:**

| Component | Meaning |
|-----------|---------|
| `hostssl` | Require SSL connection |
| `all` (first) | Applies to all databases |
| `all` (second) | Applies to all users |
| `172.456.68.78/32` | Only this exact IP (`/32` = single IP) |
| `scram-sha-256` | Strongest authentication method |

> 💡 **Security tip**: Replace `all` with specific database and user names to limit access.

### Step 3: Configure Firewall (UFW)

```bash
# Allow specific IP to access port 5432
sudo ufw allow from 172.456.68.78 to any port 5432
# Block all other IPs
sudo ufw deny 5432
```

Check firewall status:

```bash
sudo ufw status
```

> 🛡️ **Two layers of protection**: Firewall (UFW) + pg_hba.conf = Double security

### Step 4: Restart PostgreSQL

```bash
sudo systemctl restart postgresql
```

---

## 4. Verify Connection

### Check PostgreSQL is listening on correct IP

```bash
sudo ss -lntp | grep 5432
```

Expected output:

```
LISTEN    0    244    <SERVER_PUBLIC_IP>:5432    *:*
LISTEN    0    244    127.0.0.1:5432             *:*
```

### Test connection from local machine

```bash
psql -h <SERVER_PUBLIC_IP> -U <username> -d <database_name>
```

---

## Appendix: Transaction Isolation Explained

### What is Transaction Isolation?

When **multiple requests/users** read and write to the database **simultaneously**, these issues can occur:

| Issue | Description |
|-------|-------------|
| **Dirty read** | Reading uncommitted data |
| **Non-repeatable read** | Reading the same record but getting different results |
| **Phantom read** | Subsequent query returns additional "ghost" records |
| **Lost update** | Two requests overwrite each other |

**Isolation level** determines whether to allow or prevent these phenomena.

### Isolation Levels in PostgreSQL

| Level | Dirty Read | Non-repeatable | Phantom | Performance |
|-------|------------|----------------|---------|-------------|
| `READ UNCOMMITTED` | ❌ (PostgreSQL maps to READ COMMITTED) | ⚠️ Possible | ⚠️ Possible | 🚀 High |
| `READ COMMITTED` | ❌ No | ⚠️ Possible | ⚠️ Possible | 🚀 High |
| `REPEATABLE READ` | ❌ No | ❌ No | ⚠️ Possible | ⚖️ Medium |
| `SERIALIZABLE` | ❌ No | ❌ No | ❌ No | 🐢 Slow |

> 📌 **PostgreSQL defaults to `READ COMMITTED`** - suitable for 90% of applications.

### How does READ COMMITTED work?

**Rules:**
- Each `SELECT` only sees **committed** data
- Cannot see data being updated by another transaction that hasn't committed yet

**Example:**

```
Table accounts: id=1, balance=1000

┌─────────────────────────────────┬─────────────────────────────────┐
│        Transaction A            │        Transaction B            │
├─────────────────────────────────┼─────────────────────────────────┤
│ BEGIN;                          │                                 │
│ UPDATE accounts                 │                                 │
│   SET balance = 500             │                                 │
│   WHERE id = 1;                 │                                 │
│ -- not yet COMMIT               │                                 │
│                                 │ SELECT balance FROM accounts    │
│                                 │   WHERE id = 1;                 │
│                                 │ --> Result: 1000 (cannot see    │
│                                 │     uncommitted data)           │
│ COMMIT;                         │                                 │
│                                 │ SELECT balance FROM accounts    │
│                                 │   WHERE id = 1;                 │
│                                 │ --> Result: 500                 │
└─────────────────────────────────┴─────────────────────────────────┘
```

### When to use which isolation level?

| Use Case | Recommended |
|----------|-------------|
| Standard CRUD APIs | `READ COMMITTED` |
| Reports, statistics | `READ COMMITTED` |
| Orders, booking | `REPEATABLE READ` or `SELECT ... FOR UPDATE` |
| Finance, accounting | `SERIALIZABLE` |

### Why SET isolation for ROLE?

```sql
ALTER ROLE app_user SET default_transaction_isolation TO 'read committed';
```

**Benefits:**
- PostgreSQL still uses `READ COMMITTED` by default
- However:
    - Apps can override it arbitrarily
    - Migrations / tools / scripts might set different isolation levels
- ✅ Ensures **all connections** from this user have consistent behavior
- ✅ Prevents developers/tools from accidentally setting different isolation levels
- ✅ Easier to debug and predict behavior

---

## 📚 References

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html)
