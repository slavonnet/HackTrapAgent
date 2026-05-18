# Local build assets

This directory contains local files copied into images during Docker build.

Structure:

- `local/ssh/` - local SSH service settings and seed users.
- `local/fail2ban/` - local fail2ban configuration used by the `fail2ban` image.

You can override defaults by editing files in this directory and rebuilding images.
