# NAME

beacon - Consult a DNS beacon and maybe create a reverse tunnel to a control node

# SYNOPSIS

    beacon [-h] [-i beacon_id] [-d beacon_domain] [-t tunnel_host] [-u user]
           [-k ssh_key] [-s ssh_user] [--install] [--interactive]

# DESCRIPTION

beacon tells individual worker nodes in a fleet to create reverse SSH tunnels to
a central tunnel host when they see a particular signal appear in a DNS beacon.

    +--------+     +--------+
    | worker |     | NAT    +---------+
    | node   +-----> gateway|         |
    +--------+     +--------+         |
                                +-----v-------+      +--------------+
                                |             |      |              |
                                | tunnel host <------+ support team |
                                |             |      |              |
                                +-----^-------+      +--------------+
    +--------+     +--------+         |
    | worker |     | NAT    +---------+
    | node   +-----> gateway|
    +--------+     +--------+

On the DNS server for "example.com", create a TXT record for
"e0fb0955a.example.com" with the value of the
port the reverse SSH tunnel should be created on ("52001" below):

    > dig +noall +answer -t TXT e0fb0955a.example.com
    e0fb0955a.example.com. 592 IN TXT "52001"

On the worker node, run this script in a cron job and it'll connect if it sees
the beacon, and skip processing if the tunnel is already up. (See INSTALLATION
section for more.)

    > grep beacon /etc/crontab
    */5 * * * *    myuser    /usr/local/bin/beacon -i e0fb0955a [...]

The worker node's SSH user must be able to log in to the tunnel host non-interactively, e.g.:

    > ssh -i /home/myuser/.ssh/id_rsa -l myuser tunnel.example.com

On the tunnel host, you can find open tunnels in the 52xxx port range using:

    > sudo netstat -tpln | grep ssh | grep -E ':52[0-9]{3}'
    tcp    0    0 127.0.0.1:52001     0.0.0.0:*      LISTEN      31459/sshd: beaconuser
    tcp6   0    0 ::1:52001           :::*           LISTEN      31459/sshd: beaconuser

You can then connect to the worker node from the tunnel host using:

    > ssh localhost -p 52001

You can close tunnels from the tunnel host end by killing specific sshd processes:

    > kill 31459 # PID from the example above

# INSTALLATION

The easiest way to install beacon is with the interactive installer:

    curl -s https://raw.githubusercontent.com/jlabusch/beacon/v1.0.3/webinstall | sudo bash

The installer will create /usr/local/bin/beacon, prompt for configuration and
add the job to /etc/crontab.

# USAGE

List of optional arguments:

    --beacon-domain=DOMAIN, -d
        default is "example.com"

    --beacon-id=ID, -i
        default is "e0fb0955a"

    --help, -h
        show this message

    --install
        install beacon into /etc/crontab, to be run as jacques in 5 minute
        intervals and taking additional command line options into account when
        configuring the job (-c, -d, -i, -k, -u, -t)

    --interactive
        run interactively, i.e. without putting the tunnel in a detached screen session
        (ignored with --install)

    --ssh-key=PATH, -k
        default is `~/.ssh/id_rsa`

    --ssh-user=USER, -s
        default is that of --user or $USER

    --tunnel-host=HOST, -t
        default is "tunnel.example.com"

    --user=USER, -u
        user to execute the cron job as; default is $USER

    --uninstall
        remove beacon from the crontab but leave the actual script in place on
        the filesystem

# AUTHENTICATION

The tunnels are built on SSH, and beacon does not attempt to manage your SSH keys for you.
The only restriction on keys is that they should be non-interactive, e.g. not requiring
that a passphrase be entered.
