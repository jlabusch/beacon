# NAME

beacon - Consult a DNS beacon and maybe create a reverse tunnel to a control node

# SYNOPSIS

`beacon [-h] [-i beacon_id] [-d beacon_domain] [-t tunnel_host] [-k ssh_key] [-u ssh_user]`

# DESCRIPTION

`beacon` tells individual nodes in a fleet to create reverse SSH tunnels to a central tunnel host when they see a particular signal appear in a DNS beacon.

    +-------+     +--------+
    | fleet |     | NAT    +---------+
    | node  +-----> gateway|         |
    +-------+     +--------+         |
                               +-----v-------+      +--------------+
                               |             |      |              |
                               | tunnel host <------+ support team |
                               |             |      |              |
                               +-----^-------+      +--------------+
    +-------+     +--------+         |
    | fleet |     | NAT    +---------+
    | node  +-----> gateway|
    +-------+     +--------+

On the DNS server for ${BEACON_DOMAIN}, create a TXT record for `${BEACON_ID}.${BEACON_DOMAIN}` with the value of the port the reverse SSH tunnel should be created on. ("52001" in the example below)

    > dig +noall +answer -t TXT ${BEACON_ID}.${BEACON_DOMAIN}
    beacon5.example.com. 592 IN TXT "52001"

On the fleet node, run this script in a cron job and it'll connect if it sees the beacon, and skip processing if the tunnel is already up.

    > grep beacon /etc/crontab
    */5 *	* * *	beaconuser    /opt/beacon

The fleet node's SSH user must be able to log in to the tunnel host non-interactively:

    > ssh -i $SSH_KEY -l $SSH_USER $TUNNEL_HOST

On the tunnel host, you can find open tunnels in the 52xxx port range using:

    > sudo netstat -tpln | grep ssh | grep 52
    tcp    0    0 127.0.0.1:52001     0.0.0.0:*      LISTEN      31459/sshd: beaconuser
    tcp6   0    0 ::1:52001           :::*           LISTEN      31459/sshd: beaconuser

On the tunnel host, you can close tunnels by killing specific sshd processes:
    > kill 31459

List of optional arguments:

    -h, --help
        show this message

    -i, --beacon-id=ID
        default is "e0fb0955a20e6f6e4e6d5a16cc84dc061" (which has no special significance)

    -d, --beacon-domain=DOMAIN
        default is "example.com"

    -t, --tunnel-host=HOST
        default is "tunnel.example.com"

    -k, --ssh-key=PATH
        default is "~/.ssh/id_rsa"

    -u, --ssh-user=USER
        default is "$USER"

# AUTHENTICATION

The tunnels are built on SSH, and beacon does not attempt to manage your SSH keys for you. The only restriction on keys is that they should be non-interactive, e.g. not requiring that a passphrase be entered.
