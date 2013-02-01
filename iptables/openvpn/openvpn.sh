openvpn() {
	# eth0
	WANETH=$1
	# tap0
	VPNETH=$2
	# 10.0.0.1/24
	VPNNET=$3
	# 6001
	VPNPORT=$4
	# udp
	VPNPROTO=$5
	iptables -A INPUT -p $VPNPROTO --dport $VPNPORT -j ACCEPT
	iptables -A INPUT -s $VPNNET -j ACCEPT
	iptables -t nat -A POSTROUTING -o $WANETH -s $VPNNET -j MASQUERADE
	iptables -A FORWARD -i $VPNETH -o $WANETH -s $VPNNET -j ACCEPT
}
openvpn_filter() {
	# /root/list.txt
	LISTFILE=$1
	# udp
	VPNPROTO=$2
	iptables -N ACCEPT_VPN_WHITE_LIST
	for addr in `cat $LISTFILE`
	do
	    iptables -A ACCEPT_VPN_WHITE_LIST -s $addr -j ACCEPT
	done
	iptables -A INPUT -p $VPNPROTO --dport $VPNPORT -j ACCEPT_VPN_WHITE_LIST
}
