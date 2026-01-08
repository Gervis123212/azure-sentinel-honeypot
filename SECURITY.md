# Security Policy

This project intentionally deploys vulnerable infrastructure. That's the point—it's a honeypot. But that doesn't mean security considerations go out the window. This document clarifies what's intentional, what's not, and how to use this project responsibly.

---

## Purpose

This project is a **cybersecurity learning tool and portfolio demonstration**. It creates a deliberately vulnerable environment for:

- Educational purposes
- Security research
- Threat intelligence gathering
- Portfolio demonstration

---

## Important Warnings

Before deploying, understand these risks:

1. **Do NOT deploy this in production environments** — The honeypot has no real defenses
2. **Do NOT use real credentials or sensitive data** — Treat the VM as compromised from day one
3. **Isolate the honeypot from internal networks** — Use a separate VNET with no peering
4. **Monitor costs** — Azure resources incur charges; set up billing alerts
5. **Review Azure security best practices** — Understand what you're exposing before you expose it

---

## Expected Vulnerabilities

The following are **intentional** and part of the honeypot design. These are not bugs:

| Configuration | Purpose |
|---------------|---------|
| Open RDP port (3389) | Attracts brute-force attempts for logging |
| Disabled Network Level Authentication | Allows attackers to reach the login screen |
| Disabled Windows Firewall | Ensures all traffic reaches the VM |
| Weak authentication settings | Encourages login attempts |

If you find these in the code, they're working as intended.

---

## Reporting Actual Security Issues

If you discover a security vulnerability in the **project infrastructure itself** (not the honeypot design), such as:

- Exposed credentials in code (API keys, passwords, tokens)
- Insecure configurations that aren't part of the honeypot design
- Vulnerabilities in the automation pipeline that could be exploited

Please report responsibly:

1. **Do NOT open a public GitHub issue** for security vulnerabilities
2. Use GitHub's Security Advisory feature or contact directly
3. Provide detailed information about the vulnerability
4. Allow reasonable time for a fix before public disclosure

---

## Responsible Use

**This project is for:**
- Learning cloud security concepts
- Understanding attacker behavior through real data
- Building threat intelligence capabilities
- Demonstrating SOC automation skills

**This project is NOT for:**
- Attacking or scanning systems you don't own
- Any illegal or unethical activities
- Production deployments or storing real data
- Launching attacks against third parties

By using this project, you agree to comply with all applicable laws and regulations, including the Computer Fraud and Abuse Act (CFAA) and equivalent laws in your jurisdiction.

---

## Questions?

If you're unsure whether a particular use case is appropriate, err on the side of caution. This is a learning tool—use it to learn, not to cause harm.
