---
name: linux-server-admin
description: Use for Linux server administration over SSH: sshd hardening and custom ports, firewall (ufw/nftables), nginx, systemd services, Cloudflare tunnels, system optimisation and cleanup scripts on Ubuntu/Debian. Safety-critical: lockout and data loss prevention.
---
# Linux server administration (Ubuntu/Debian)

Changes here can lock the user out or destroy data. Default to **read-only inspection and a written plan**; run nothing on a remote or production host without explicit approval, and show the exact commands first.

## SSH and custom ports (lockout-safe procedure)
1. Inspect first: `sshd -T | grep -Ei 'port|permitroot|passwordauth|pubkey|allowusers'`, `ss -tlnp | grep sshd`, active firewall rules, and whether SSH runs via socket activation (`systemctl status ssh.socket`) — on newer Ubuntu the **socket unit** owns the port, so editing only `sshd_config` may not change it.
2. Prefer drop-ins: `/etc/ssh/sshd_config.d/10-local.conf`, not edits to the main file.
3. **Open the new port in the firewall before switching** (and in any cloud/provider firewall). Keep the old port open until the new one is proven.
4. Validate: `sshd -t`. Reload (not restart) and **keep the existing session open**; test a second, new connection on the new port (`ssh -p <port> user@host`) before closing anything.
5. Only then close the old port and remove it from config. Record rollback steps (console/KVM access, the exact file to revert).
6. Hardening to propose, not force: key-only auth, `PermitRootLogin no`, `AllowUsers`, `MaxAuthTries`, fail2ban/ufw rate limiting. A non-standard port reduces log noise; it is not a security control on its own.
Never disable password auth before a working key login is confirmed in a separate session.

## Firewall
`ufw status verbose` first. Allow before enabling (`ufw allow <port>/tcp`, then `ufw enable`). For reverse-proxied apps expose only 80/443 (or nothing when using a Cloudflare tunnel) and bind apps to `127.0.0.1`.

## nginx
`nginx -t` before every reload; keep site configs in `sites-available` with symlinks; WebSocket upgrade headers where needed; set body size, timeouts and security headers deliberately; when behind Cloudflare/tunnel, restore real client IPs only from trusted ranges.

## systemd
Unit files in `/etc/systemd/system`; run services as a dedicated user with hardening (`NoNewPrivileges`, `ProtectSystem=strict`, `ReadWritePaths`, `PrivateTmp`); `systemctl daemon-reload`, `systemctl status`, `journalctl -u <unit> -n 100 --no-pager`. Keep the previous version for rollback on updates.

## Optimisation and cleanup
- Measure first: `uptime`, `free -h`, `df -h`, `du -xh --max-depth=1 /var | sort -h`, `ss -s`, `journalctl --disk-usage`, `iostat`/`vmstat` if installed, `systemd-analyze blame`.
- Safe cleanup candidates (list, then ask): `apt autoremove`/`apt clean`, `journalctl --vacuum-time`, old kernels (never the running one), rotated logs, unused container images (`docker image prune` only after checking what is unused).
- Kernel/sysctl tuning, swap and I/O scheduler changes: change one thing, document the previous value, make it persistent only after it proves useful.
- Cleanup scripts: dry-run by default (`--apply` to act), absolute paths, no `rm -rf` on computed or empty variables, log every deletion, never touch data directories, databases, backups or `/var/lib/*` without naming them.

## Scripts and reporting
`set -euo pipefail`, quoted variables, LF endings, idempotent, `shellcheck` if available. Report what was inspected, what was changed (with the reverting command), and what is unverified. Pair with `selfhosted-containers` for container workloads.
