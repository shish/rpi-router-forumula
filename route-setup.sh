#!/bin/bash
if [ "${interface}" = "wwanV" ]; then
	case "${reason}" in BOUND|RENEW|REBIND|REBOOT)
		ip route | grep -q 'tos 0x04' || ip route add default tos 0x04 via 192.168.8.1 dev wwanV
		;;
	esac
fi

if [ "${interface}" = "wwanT" ]; then
	case "${reason}" in BOUND|RENEW|REBIND|REBOOT)
		ip route | grep -q 'tos 0x08' || ip route add default tos 0x08 via 192.168.8.1 dev wwanT
		;;
	esac
fi
