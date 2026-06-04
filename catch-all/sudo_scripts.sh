#!/usr/bin/env bash

case "$1" in
  backup)
    /home/usuario/scripts/backup.sh
    ;;
  deploy)
    /home/usuario/scripts/deploy.sh
    ;;
  *)
    echo "No permitido"
    exit 1
    ;;
esac
