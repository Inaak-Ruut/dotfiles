#!/usr/bin/env sh

if [ -e /var/cache/eix/portage.eix ]; then 
    cp -a /var/cache/eix/portage.eix /var/cache/eix/previous.eix; 
fi
eix-update
if [ -e /var/cache/eix/previous.eix ]; then 
    eix-diff; 
fi

# Save as:
# /etc/portage/repo.postsync.d/eix.sh

# Do not forget to make the file executable:
# chmod +x /etc/portage/repo.postsync.d/eix.sh