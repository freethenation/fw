#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Got to run as root"
  exit 1
fi
ABSOLUTE_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/`basename "${BASH_SOURCE[0]}"`
if [ -z "$IPTABLES" ]; then
  #run for ip6tables
  export IPTABLES=$(which ip6tables)
  bash $ABSOLUTE_PATH
  #run for iptables
  IPTABLES=$(which iptables)
fi

#Remove all past rules
iptables --flush
iptables -X
iptables -t nat --flush
iptables -t nat -X
iptables -t mangle --flush
iptables -t mangle -X
#Set default policies
$IPTABLES --policy INPUT DROP
$IPTABLES --policy OUTPUT ACCEPT
$IPTABLES --policy FORWARD DROP
#Allow ping
$IPTABLES -A INPUT -p icmp -j ACCEPT
#Allow loopback
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT
#Allow all incoming on established connections
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#Apply firewall
cat firewall | grep --invert-match "#" | awk '{     \
  rule = " --protocol " $1 " --dport " $2;          \
  if ($3 != "") rule = rule " --in-interface " $3;  \
  print rule " -A INPUT -j ACCEPT";                 \
}' | xargs -L1 sudo $IPTABLES

#Echo setuo
echo $IPTABLES
$IPTABLES -L -v
echo ""