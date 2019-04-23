# NAME

`beacon` - Consult a DNS beacon and maybe create a reverse tunnel to a control node

# SYNOPSIS

    beacon [-h] [-i beacon_id] [-d beacon_domain] [-t tunnel_host] [-u user]
           [-k ssh_key] [-s ssh_user] [--install] [--interactive]

# DESCRIPTION

`beacon` tells individual worker nodes in a fleet to create reverse SSH tunnels to
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

On the DNS server for `beacon-domain`, create a TXT record for
`<beacon-id>.<beacon-domain>` with the value of the port the reverse SSH
tunnel should be created on (`52001` below):

    > dig +noall +answer -t TXT my_id.my_domain.com
    my_id.my_domain.com. 592 IN TXT "52001"

On the worker node, run this script in a cron job and it'll connect if it sees
the beacon, and skip processing if the tunnel is already up. (See INSTALLATION
section for more.)

    > grep beacon /etc/crontab
    */5 * * * *    my_user    /usr/local/bin/beacon -i my_id [...]

The worker node's SSH user must be able to log in to the tunnel host non-interactively, as though by:

    > ssh -i $HOME/.ssh/id_rsa -l my_user tunnel_host.my_domain.com

On the tunnel host, you can find open tunnels in the 52xxx port range using:

    > sudo netstat -tpln | grep ssh | grep -E ':52[0-9]{3}'
    tcp   0   0 127.0.0.1:52001    0.0.0.0:*    LISTEN    31459/sshd: my_user
    tcp6  0   0 ::1:52001          :::*         LISTEN    31459/sshd: my_user

You can then connect to the worker node from the tunnel host using:

    > ssh localhost -p 52001

You can close tunnels from the tunnel host end by killing specific sshd processes:

    > kill 31459 # PID from the example above

# PROXYING WEB APPLICATIONS

Shells are nice, but sometimes you want to be able to see a web interface.

Here's how we did it:

    # on tunnel host, create a SOCKS proxy from local port
    # 51800 (chosen randomly) to the worker node on 52001
    > ssh -D 51800 -N -p 52001 localhost

    # on your workstation, create an SSH tunnel to the SOCKS proxy
    > ssh -N -L 51800:localhost:51800 tunnel_host.mydomain.com

    # Now tell your browser to use the local proxy
    curl -x socks5://localhost:51800 $REMOTE_URI

Browsers can be a bit funny about SOCKS5 proxies, and if you're using
Firefox I'd immediately recommend using something like FoxyProxy. YMMV.

# INSTALLATION

The easiest way to install beacon is with the interactive installer:

    curl -s https://raw.githubusercontent.com/jlabusch/beacon/v1.0.6/webinstall | sudo bash

The installer will create `/usr/local/bin/beacon`, prompt for configuration and
add the job to `/etc/crontab`.

If you already have beacon installed and know what options you want to run with,
you can add or update the cron job by appending the `--install` option to your
usual invocation, e.g.

    > sudo beacon -i my_id -d my_domain.com [...] --install

# USAGE

List of optional arguments:

    --beacon-domain=DOMAIN, -d
        A domain whose DNS records you can change

    --beacon-id=ID, -i
        The unique subdomain that this worker node should query

    --help, -h
        This message

    --install
        Install beacon into /etc/crontab, to be run in 5 minute intervals and
        taking additional command line options into account when configuring
        the job (-c, -d, -i, -k, -u, -t)

    --interactive
        Run interactively, i.e. without putting the tunnel in a detached screen
        session (ignored with --install). This is usually only needed for debugging,
        e.g. figuring out that your SSH key is prompting for a passphrase.

    --ssh-key=PATH, -k
        Default is "$HOME/.ssh/id_rsa"

    --ssh-user=USER, -s
        Default is "$USER"

    --tunnel-host=HOST, -t
        A host you can land the reverse tunnels on.

    --user=USER, -u
        User to execute the cron job as; default is "$USER"

    --uninstall
        Remove beacon from the crontab but leave the actual script in place on
        the filesystem. Intentional quirk: it'll only uninstall the entry for
        the script you're running, i.e. "/foo/beacon" and "/bar/beacon" are not
        equivalent.

# AUTHENTICATION

The tunnels are built on SSH, and beacon does not attempt to manage your SSH keys
for you. The only restriction on keys is that they should be non-interactive,
e.g. not requiring that a passphrase be entered.
