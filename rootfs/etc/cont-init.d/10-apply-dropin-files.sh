#!/bin/sh

set -e


# Applying OpenDKIM drop-in .conf files.
for file in /etc/opendkim/conf.d/*.conf; do
  [ -f "$file" ] || continue
  printf "\n\n#\n# %s\n#\n" "$file" >> /etc/opendkim/opendkim.conf
  cat "$file" >> /etc/opendkim/opendkim.conf
done
