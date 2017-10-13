#!/bin/bash

clear
echo -e "Script para configuração RPI Hotspot Wireless\n"

Instalado_hostapd=$(dpkg -l | grep hostapd | awk '{print substr($0, 1, 2)}')
Instalado_udhcpd=$(dpkg -l | grep udhcpd | awk '{print substr($0, 1, 2)}')
if [ "$Instalado_hostapd" = "ii" ] && [ "$Instalado_udhcpd" = "ii" ]
then
	echo -e "Os programas necessários já estão instalados, conclua a configuração.\n"
	service hostapd stop
	service udhcpd stop
	cp /etc/udhcpd_Hotspot_Original.conf /etc/udhcpd.conf
	cp /etc/default/udhcpd_Hotspot_Original /etc/default/udhcpd
	cp /etc/network/interfaces_Hotspot_Original /etc/network/interfaces
	cp /etc/default/hostapd_Hotspot_Original /etc/default/hostapd
	cp /etc/sysctl_Hotspot_Original.conf /etc/sysctl.conf
	cp /etc/rc.local_Hotspot_Original /etc/rc.local

else
	echo -e "NECESSARIO CONEXÃO COM A INTERNET\n\n"
	echo -e "O hostapd e udhcpd não estão instalados. Por favor Aguarde...\n"
	apt-get update && sudo apt-get install hostapd udhcpd -y --fix-missing
	if [ ! -f /etc/udhcpd_Hotspot_Original.conf ]
	then
		cp /etc/udhcpd.conf /etc/udhcpd_Hotspot_Original.conf
	fi
	if [ ! -f /etc/default/udhcpd_Hotspot_Original ]
	then
		cp /etc/default/udhcpd /etc/default/udhcpd_Hotspot_Original
	fi
	if [ ! -f /etc/network/interfaces_Hotspot_Original ]
	then
		cp /etc/network/interfaces /etc/network/interfaces_Hotspot_Original
	fi
	if [ ! -f /etc/default/hostapd_Hotspot_Original ]
	then
		cp /etc/default/hostapd /etc/default/hostapd_Hotspot_Original
	fi
	if [ ! -f /etc/sysctl_Hotspot_Original.conf ]
	then
		cp /etc/sysctl.conf /etc/sysctl_Hotspot_Original.conf
	fi
	if [ ! -f /etc/rc.local_Hotspot_Original ]
	then
		cp /etc/rc.local /etc/rc.local_Hotspot_Original
	fi
	echo -e "\n"
fi

echo -e "Inciando configuração para DHCP."
echo -e "Mais opções consulte o arquivo \"/etc/udhcpd_Hotspot_Original.conf\".\n"
echo -e "Segue abaixo configurações usadas:\n"
echo "Range de IP. do DHCP:"
echo "Inicio = 192.168.125.2"
echo "Fim = 192.168.125.254"
echo "Mascára de rede = 255.255.255.0"
echo "Gateway = 192.168.125.1"
echo "DNS = " $(cat /etc/resolv.conf | grep nameserver | awk '{print substr($0, 12, 15)}')
echo "Roteador da rede = 192.168.125.0"
echo -e "Tempo de concessão = 10 dias\n"
echo "Deseja alterar as configurações?"
echo "Sim = s ou Não = n | Em branco = Não"
read Opcao
	if [ "$Opcao" = "s" ] || [ "$Opcao" = "S" ]
	then
		echo "Digite o IP inicial:"
		read DHCP_IP_Inicial
		echo "Digite o IP final:"
		read DHCP_IP_Final
		echo "Digite a mascára de rede:"
		read DHCP_Mascara
		echo "Digite o gateway:"
		read DHCP_Gateway
		echo "Digite o DNS:"
		read DHCP_DNS
		echo "Digite a rede:"
		read DHCP_Rede
		echo "Dias de concessão:"
		read DHCP_Dias
	else
		DHCP_IP_Inicial=192.168.125.2
		DHCP_IP_Final=192.168.125.254
		DHCP_Mascara=255.255.255.0
		DHCP_Gateway=192.168.125.1
		DHCP_DNS=$(cat /etc/resolv.conf | grep nameserver | awk '{print substr($0, 12, 15)}')
		DHCP_Rede=192.168.125.0
		DHCP_Dias=10
	fi

#Configuração de dhcp
echo -e "\nRealizando alterações nos arquivos abaixo:"
echo "/etc/udhcpd.conf"
echo "/etc/default/udhcpd"
echo -e "#Arquivo original em \"/etc/udhcpd_Hotspot_Original.conf\"." > /etc/udhcpd.conf
echo "start $DHCP_IP_Inicial" >> /etc/udhcpd.conf
echo "end $DHCP_IP_Final" >> /etc/udhcpd.conf
echo "interface wlan0" >> /etc/udhcpd.conf
echo "remaining yes" >> /etc/udhcpd.conf
echo "opt subnet $DHCP_Mascara" >> /etc/udhcpd.conf
echo "opt router $DHCP_Gateway" >> /etc/udhcpd.conf
echo "opt dns $DHCP_DNS" >> /etc/udhcpd.conf
DHCP_Dias=$(($DHCP_Dias*86400))
echo "opt lease $DHCP_Dias" >> /etc/udhcpd.conf
sed -i -e '/DHCPD_ENABLED="no"/c DHCPD_ENABLED="yes"' /etc/default/udhcpd

#Configuração do wlan0 estático
echo "Realizando alterações no arquivo abaixo:"
echo "/etc/network/interfaces"
ifconfig wlan0 "$DHCP_Gateway"
echo -e "#arquivo original em \"/etc/network/interfaces_Hotspot_Original\".\n" >> /etc/network/interfaces
echo "auto eth0" >> /etc/network/interfaces
echo "allow-hotplug eth0" >> /etc/network/interfaces
echo -e "iface eth0 inet dhcp\n" >> /etc/network/interfaces
echo "allow-hotplug wlan0" >> /etc/network/interfaces
echo "iface wlan0 inet static" >> /etc/network/interfaces
echo "$(printf "\t")address $DHCP_Gateway" >> /etc/network/interfaces
echo "$(printf "\t")netmask $DHCP_Mascara" >> /etc/network/interfaces
echo "$(printf "\t")network $DHCP_Rede" >> /etc/network/interfaces

echo -e "\nIniciando configuração do HostAPD - Wireless\n"
echo -e "OBS. Deixe a senha em branco caso não queira senha na rede.\n"
echo "Digite o nome da rede WIFI:"
read WIFI_Nome
echo "Digite a senha, a senha deve ter mais de 8 digítos:"
read WIFI_Senha
echo "Digite o canal da rede, de 1 a 13:"
read WIFI_Canal
echo -e "\nCriando arquivo:"
echo "/etc/hostapd/hostapd.conf"

#Configuração do HostAPD 

echo "interface=wlan0" > /etc/hostapd/hostapd.conf
echo "ssid=$WIFI_Nome" >> /etc/hostapd/hostapd.conf
echo "hw_mode=g" >> /etc/hostapd/hostapd.conf
echo "channel=$WIFI_Canal" >> /etc/hostapd/hostapd.conf
echo "auth_algs=1" >> /etc/hostapd/hostapd.conf
if [ -z $WIFI_Senha ]
then
	echo "wmm_enabled=0" >> /etc/hostapd/hostapd.conf
else	
	echo "driver=nl80211" >> /etc/hostapd/hostapd.conf
	echo "macaddr_acl=0" >> /etc/hostapd/hostapd.conf
	echo "ignore_broadcast_ssid=0" >> /etc/hostapd/hostapd.conf
	echo "wpa=2" >> /etc/hostapd/hostapd.conf
	echo "wpa_passphrase=$WIFI_Senha" >> /etc/hostapd/hostapd.conf
	echo "wpa_key_mgmt=WPA-PSK" >> /etc/hostapd/hostapd.conf
	echo "rsn_pairwise=CCMP" >> /etc/hostapd/hostapd.conf
	echo "wpa_pairwise=TKIP" >> /etc/hostapd/hostapd.conf
fi
echo "Editando arquivo:"
echo "/etc/default/hostapd"
sed -i -e '/#DAEMON_CONF=""/c DAEMON_CONF="/etc/hostapd/hostapd.conf"' /etc/default/hostapd

echo "Habilitando encaminhamento de rede:"
echo "Editando arquivo:"
echo -e "/etc/sysctl.conf"
sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "Editando arquivo:"
echo -e "/etc/rc.local"
sed -i -e '/^exit 0/i sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE' /etc/rc.local
sed -i -e '/^exit 0/i sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT' /etc/rc.local
sed -i -e '/^exit 0/i sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT' /etc/rc.local

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

echo "Ativando na inicialização:"
update-rc.d hostapd enable
update-rc.d udhcpd enable

echo -e "\nConcluido\n"
echo "Necessário realizar o reinicio do Raspberry."
echo " Deseja reiniciar?" 
echo "Sim = s ou Não = n | Em branco = Não"
read Opcao
	if [ "$Opcao" = "s" ] || [ "$Opcao" = "S" ]
	then
		reboot
	fi