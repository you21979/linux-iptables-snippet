basic() {
	# eth0
	WANETH=$1
	# eth1
	LOCALETH=$2
	# 255.255.255.0
	LOCALNET_MASK=$3
	# 192.168.0.1
	LOCALNET_ADDR=$4

	LOCALNET=$LOCALNET_ADDR/$LOCALNET_MASK

	# ファイアウォール停止(すべてのルールをクリア)
	/etc/init.d/iptables stop

	iptables -F
	iptables -t nat -F

	# デフォルトルール(以降のルールにマッチしなかった場合に適用するルール)設定
	iptables -P INPUT   DROP   # 受信はすべて破棄
	iptables -P OUTPUT  ACCEPT # 送信はすべて許可
	iptables -P FORWARD DROP   # 通過はすべて破棄

	# FORWARD
	iptables -t nat -A POSTROUTING -o $LOCALETH -s $LOCALNET -j MASQUERADE
	iptables -A FORWARD -i $WANETH -o $LOCALETH -s $LOCALNET -j ACCEPT
	iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

	# 自ホストからのアクセスをすべて許可
	iptables -A INPUT -i lo -j ACCEPT

	# 内部からのアクセスをすべて許可
	iptables -A INPUT -s $LOCALNET -j ACCEPT

	# 内部から行ったアクセスに対する外部からの返答アクセスを許可
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

	# フラグメント化されたパケットはログを記録して破棄
	iptables -A INPUT -f -j LOG --log-prefix '[IPTABLES FRAGMENT] : '
	iptables -A INPUT -f -j DROP

	# 外部とのNetBIOS関連のアクセスはログを記録せずに破棄
	# ※不要ログ記録防止
	iptables -A INPUT ! -s $LOCALNET -p tcp -m multiport --dports 135,137,138,139,445 -j DROP
	iptables -A INPUT ! -s $LOCALNET -p udp -m multiport --dports 135,137,138,139,445 -j DROP
	iptables -A OUTPUT ! -d $LOCALNET -p tcp -m multiport --sports 135,137,138,139,445 -j DROP
	iptables -A OUTPUT ! -d $LOCALNET -p udp -m multiport --sports 135,137,138,139,445 -j DROP

	# 1秒間に4回を超えるpingはログを記録して破棄
	# ※Ping of Death攻撃対策
	iptables -N LOG_PINGDEATH
	iptables -A LOG_PINGDEATH -m limit --limit 1/s --limit-burst 4 -j ACCEPT
	iptables -A LOG_PINGDEATH -j LOG --log-prefix '[IPTABLES PINGDEATH] : '
	iptables -A LOG_PINGDEATH -j DROP
	iptables -A INPUT -p icmp --icmp-type echo-request -j LOG_PINGDEATH

	# 全ホスト(ブロードキャストアドレス、マルチキャストアドレス)宛パケットはログを記録せずに破棄
	# ※不要ログ記録防止
	iptables -A INPUT -d 255.255.255.255 -j DROP
	iptables -A INPUT -d 224.0.0.1 -j DROP
}
