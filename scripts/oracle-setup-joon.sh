#!/usr/bin/env bash
set -euo pipefail

sudo bash "$(dirname "$0")/oracle-vm-setup.sh" joon admin ubuntu joon-aca joon@africacode.academy
