#!/bin/bash
set -e
cd "$(dirname "$(readlink -f "$0")")"

# find logs/pointSystem/ -type f -mmin -60 | egrep -q . || echo EXIT
