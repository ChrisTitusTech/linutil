# Configuring Linux DNS for Tailscale
# Sourced from the official documentation: https://tailscale.com/kb/1188/linux-dns
# Tailscale attempts to interoperate with any Linux DNS configuration it finds already present. Unfortunately, some are not entirely amenable to cooperatively managing the host's DNS configuration.

# Common problems
# NetworkManager + systemd-resolved
# If you're using both NetworkManager and systemd-resolved (as in common in many distros), you'll want to make sure that /etc/resolv.conf is a symlink to /run/systemd/resolve/stub-resolv.conf. That should be the default. If not,
# When NetworkManager sees that symlink is present, its default behavior is to use systemd-resolved and not take over the resolv.conf file.

printf "Fixing /etc/resolv.conf to point to systemd-resolved stub resolver...\n"
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
printf "Fixed /etc/resolv.conf:\n"
cat /etc/resolv.conf

# After fixing, restart everything:
printf "Restarting systemd-resolved, NetworkManager, and tailscaled services...\n"
sudo systemctl restart systemd-resolved
sudo systemctl restart NetworkManager
sudo systemctl restart tailscaled
printf "Services restarted.\n"

# DHCP dhclient overwriting /etc/resolv.conf
# Without any DNS management system installed, DHCP clients like dhclient and programs like tailscaled have no other options than rewriting the /etc/resolv.conf file themselves, which results in them sometimes fighting with each other. (For instance, a DHCP renewal rewriting the resolv.conf resulting in loss of MagicDNS functionality.)
# Possible workarounds are to use resolvconf or systemd-resolved. Issue 2334 tracks making Tailscale react to other programs updating resolv.conf so Tailscale can add itself back.