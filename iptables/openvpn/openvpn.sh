openvpn() {
	VPNNET=$1
	VPNPORT=$2
	iptables -A INPUT -p udp --dport $VPNPORT -j ACCEPT
	iptables -A INPUT -s $VPNNET -j ACCEPT
	iptables -t nat -A POSTROUTING -o eth0 -s $VPNNET -j MASQUERADE
	iptables -A FORWARD -i tap0 -o eth0 -s $VPNNET -j ACCEPT
}
openvpn_filter(){
	LISTFILE=$1
	iptables -N ACCEPT_VPN_WHITE_LIST
	for addr in `cat $LISTFILE`
	do
	    iptables -A ACCEPT_VPN_WHITE_LIST -s $addr -j ACCEPT
	done
	iptables -A INPUT -p udp --dport $VPNPORT -j ACCEPT_VPN_WHITE_LIST
}
