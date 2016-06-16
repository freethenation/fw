rfw
---
"ouRFireWall" is a simple, bash-only iptables firewall script focused on Linux
container networking. It only handles port forwarding and NAT for configured
containers. Use something like UFW or Shorewall (or just raw iptables) to handle
the INPUT and OUTPUT chains.

Configuration
-------------
Example config file:
```
#dtype    dspec            protocol  port     dport
#--------------------------------------------------
docker    grafana          tcp       8080     80
lxc       blah             tcp       192      22
eth0      10.0.3.1         tcp       234      123
eth1      2001:db8::1      udp       53       53
docker    monitor
```

Each line has up to five configuration settings. The first two are required:

* `dtype` "Destination Type":  
  One of "docker", "lxc", or an interface. This indicates how the remainder of
  the line is to be interpreted.

* `dspec` "Destination Specification":  
  Name of a container, or a raw IPv4/IPv6 address. Together with `dtype`, this
  will be used to find the IP address and interface for the configuration line.
  If a raw IP address is used, `dtype` must be an interface on the host that can
  communicate with that IP. This can be used to set up basic NAT + forwarding
  for any container or VM service, or even for weird cases like fixed host VPNs.

The remaining three are optional, and only used when forwarding ports to a
container. If they are omitted, no ports will be forwarded to the container,
but it will still be NAT'd with the host, giving it access to the internet.

* `protocol`:  
  The protocol of traffic to forward to the container.

* `port` "Host Port":  
  The port that the forwarded traffic will use on the HOST side.

* `dport` "Destination Port":  
  The port that is listening for traffic inside the container.

Use with Containers
-------------------
To use this with docker, add the following to your docker daemon options (found
in `/etc/default/docker` on Ubuntu):
```
--ipv6 --iptables=false --userland-proxy=false
```

Unfortunately, LXC does not have an easy way to disable its own iptables rule
creation like docker. To use this with LXC, you'll need to modify the `lxc-net`
job (found in `/etc/init/lxc-net.conf` on Ubuntu 14.04, but probably moved on
systemd distros). Simply remove or comment out any lines that affect iptables.

UFW
---
Since this firewall only handles forwarding and NAT, you'll still want a simple
host-level firewall to protect your container host. I recommend UFW because it's
supremely simple to set up. Here's a 30 second example:
```bash
sudo ufw logging off   # disable noisy logging
sudo ufw allow 22/tcp  # allow SSH port
sudo ufw enable        # enable your new firewall
```
There is no need to allow access to your containerized services in UFW, as the
forwarding script will ensure that they can be accessed both from localhost as
well as from all other interfaces.

IPv6
----
This script NATs both IPv4 and IPv6, based on the idea that containers are
really just chroots on steroids. We'd like to make it seem as if the service is
running directly on this host, and that means sharing the same IPv4 and IPv6
address as this host.

Contributing
------------
This code is MIT licensed. See the LICENSE.txt file for details. Pull requests
are always welcome!
