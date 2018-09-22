#!/bin/sh
# set -x

# Version: 0.8
# Date:    2018-09-22
# Changelog:
#	small fixes, for wrong apikey
#	add tasmota switch for user and password use variable apikey
#	redesign with options
#	add tasmota temperature, humidity
#	add sonoff pow
#	add sonoff 4 channel
#	add espurna more than 1 relay

# More Detail and how you enable espurna restapi:
# https://github.com/xoseperez/espurna/wiki/RESTAPI

# Test:
# ./sonoff.sh -f status -c CUX2801004:4 -i 192.168.6.131 -u admin -p bilbo01 -d
# ./sonoff.sh -f status -c CUX2801004:3 -i 192.168.6.115 -a C87129A2AD1EE170 -d
# ./sonoff.sh -f status -c CUX2801004:1 -i 192.168.6.156


usage() {
	echo -e 'usage:'
	echo -e "\t $(basename $0) -f [status|switch|switch-t|switch-th] -c CUX2801xxx:x -i ipaddr [-n relayr_nr] [-a apikey] [-u user] [-p password] [-o value] [-d] [-h]\n"
	echo -e '\t examples espurna firmware:'
	echo -e "\t $(basename $0) -h # this usage info"
	echo -e "\t $(basename $0) -f switch    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456      # status switch"
	echo -e "\t $(basename $0) -f switch    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 0 # switch off"
	echo -e "\t $(basename $0) -f switch    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 1 # switch on"
	echo -e "\t $(basename $0) -f switch    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 2 # switch toggle on/off"
	echo -e "\t $(basename $0) -f switch    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 0 -n 3 # switch 4 relay off
	echo -e "\t $(basename $0) -f switch-t  -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456      # status switch and temperature"
	echo -e "\t $(basename $0) -f switch-t  -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 0 # switch off with temperature"
	echo -e "\t $(basename $0) -f switch-t  -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 1 # switch on  with temperature"
	echo -e "\t $(basename $0) -f switch-th -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456      # status switch, temperature and humidity"
	echo -e "\t $(basename $0) -f switch-th -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 0 # switch off with status temperature and humidity"
	echo -e "\t $(basename $0) -f switch-th -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 1 # switch on  with status temperature and humidity"
	echo -e "\t $(basename $0) -f status    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456      # espurna available restapi\n"
	echo -e '\t examples tasmota firmware:'
	echo -e "\t $(basename $0) -f switch    -c CUX2801xxx:x -i 192.168.x.x -u user -p password      # status switch"
	echo -e "\t $(basename $0) -f switch    -c CUX2801xxx:x -i 192.168.x.x -u user -p password -n 2 # status switch relay nr 2
	echo -e "\t $(basename $0) -f switch    -c CUX2801xxx:x -i 192.168.x.x -u user -p password -o 0 # switch off"
	echo -e "\t $(basename $0) -f switch    -c CUX2801xxx:x -i 192.168.x.x -u user -p password -o 1 # switch on"
	echo -e "\t $(basename $0) -f switch    -c CUX2801xxx:x -i 192.168.x.x -u user -p password -o 2 # switch toggle on/off"
	echo -e "\t $(basename $0) -f switch-th -c CUX2801xxx:x -i 192.168.x.x -u user -p password      # status switch, temperature and humidity"
	echo -e "\t $(basename $0) -f switch-p  -c CUX2801xxx:x -i 192.168.x.x -u user -p password      # status switch, power, volt, ampere, ..."
	echo -e "\t $(basename $0) -f status    -c CUX2801xxx:x -i 192.168.x.x -u user -p password      # tasmota status"
	exit 0
}

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
HOMEMATIC="127.0.0.1"
AVAILABLE=2 # Status: unbekannt
DEBUG=0
FUNC=''
CHANNEL=''
IPADDR=''
APIKEY=''
USER=''
PASSWD=''
VALUE=''
RELNR=''


while getopts "h?df:c:i:a:u:p:o:n:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    f)  FUNC=$OPTARG
        ;;
    c)  CHANNEL=$OPTARG
        ;;	
    i)  IPADDR=$OPTARG
        ;;
    a)  APIKEY=$OPTARG
        ;;
    u)	USER=$OPTARG
	;;
    o)  VALUE=$OPTARG
	;;
    p)  PASSWD=$OPTARG
	;;
    n)  RELNR=$OPTARG
	;;
    d)  DEBUG=1
	;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

if [ -z $FUNC ] ; then
	usage
	exit 1
elif [ -z $CHANNEL ] ; then
	usage
	exit 1
elif [ -z $IPADDR ] ; then
	usage
	exit 1
fi

if [ $DEBUG -eq 1 ] ; then
	Debugmsg1=$Debugmsg1"Function: $FUNC\n"
        Debugmsg1=$Debugmsg1"Channel:  $CHANNEL\n"
        Debugmsg1=$Debugmsg1"IP-Addr:  $IPADDR\n"
        Debugmsg1=$Debugmsg1"API-Key:  $APIKEY\n"
        Debugmsg1=$Debugmsg1"Value:    $VALUE\n"
        Debugmsg1=$Debugmsg1"user:     $USER\n"
        Debugmsg1=$Debugmsg1"password: $PASSWD\n"
	Debugmsg1=$Debugmsg1"relay nr: $RELNR\n\n"
fi

CURL=/usr/bin/curl
CURL_timout='-m 5'

set_CCU_SysVar(){
	Debugmsg1=$Debugmsg1"set_CCU_SysVar: \n\t\tValue: $1\n\t\tCCU-System-Variable: $2\n"
        if [ "x$1" != "x" ]; then
                Debugmsg1=$Debugmsg1"\t\thttp://$HOMEMATIC:8181/Test.exe?Status=dom.GetObject%28%27$2%27%29.State%28%22$1%22%29 \n"
                TEST=$(${CURL} -s $CURL_timout "http://$HOMEMATIC:8181/Test.exe?Status=dom.GetObject%28%27$2%27%29.State%28%22$1%22%29")
        else
                Debugmsg1=$Debugmsg1"\t\t$IPADDR -> set_CCU_SysVar: $2 - Fehler, keine Status.\n"
                logger -i -t $0 -p 3 "$IPADDR -> set_CCU_SysVar: $2 - Fehler, keine Status."
        fi
}

set_CUxD_state(){
	Debugmsg1=$Debugmsg1"set_CUxD_state: \n\t\tValue: $1\n\t\tCUX-CHANNEL: $2\n"
        if [ "x$1" != "x" ]; then
                Debugmsg1=$Debugmsg1"\t\thttp://$HOMEMATIC:8181/Test.exe?Status=dom.GetObject%28%27CUxD.$2.SET_STATE%27%29.State%28%22$1%22%29 \n"
                TEST=$(${CURL} -s $CURL_timout "http://$HOMEMATIC:8181/Test.exe?Status=dom.GetObject%28%27CUxD.$2.SET_STATE%27%29.State%28%22$1%22%29")
        else
                Debugmsg1=$Debugmsg1"\t\t$IPADDR -> set_CUxD_state: $2 - Fehler, keine Status.\n"
                logger -i -t $0 -p 3 "$IPADDR -> set_CUxD_state: $2 - Fehler, keine Status."
        fi
}

checkDevice(){
	TEST=$(ping -c 1 -w 1 $1)
	if [ $? -eq 0 ]
	then
		if [ -z $APIKEY ] ; then
			if [ "x$PASSWD" != 'x' ] ; then
				URL="http://${IPADDR}/cm?user=${USER}&password=${PASSWD}&cmnd=status"
			else
				URL="http://${IPADDR}/cm?cmnd=status"
			fi
			SEARCH='status'
		else
			URL="http://${IPADDR}/apis?apikey=${APIKEY}"
			SEARCH='api'
		fi

		AVAILABLE=1 # Status: erreichbar
		STATE=$(${CURL} -s ${CURL_timout} "${URL}" | grep -i ${SEARCH})
		if [ $? -eq 0 ]
		then
			AVAILABLE=1 # Status: erreichbar
		else
			AVAILABLE=0 # Status: nicht erreichbar
		fi
	else
		AVAILABLE=0 # Status: nicht erreichbar
	fi
}

func_switch(){
	if [ $AVAILABLE -ge 1 ] ; then
		if [ -z $APIKEY ] ; then
			case $VALUE in
			      0)
				VALUE="Power${RELNR}%20Off"
				;;
			      1)
				VALUE="Power${RELNR}%20On"
				;;
			      2)
				VALUE="Power${RELNR}%20Toggle"
				;;
			esac
			if [ "x$PASSWD" != 'x' ] ; then

				URL="http://${IPADDR}/cm?user=${USER}&password=${PASSWD}&cmnd=${VALUE}"
				URL2="http://${IPADDR}/cm?user=${USER}&password=${PASSWD}&cmnd=Power"
			else
				URL="http://${IPADDR}/cm?cmnd=${VALUE}"
				URL2="http://${IPADDR}/cm?cmnd=Power${RELNR}"
			fi
		else
			if [ -z $RELNR ] ; then
				RELNR=0
			fi
				
			URL="http://${IPADDR}/api/relay/${RELNR}?apikey=${APIKEY}&value=${VALUE}"
			URL2="http://${IPADDR}/api/relay/${RELNR}?apikey=${APIKEY}"
		fi
		Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
		TEST=$(${CURL} -s ${CURL_timout} "${URL}")
		Debugmsg1=$Debugmsg1"cmd: \t\t${CURL} -s ${CURL_timout} \"${URL2}\" \n"
		OUT=$(${CURL} -s ${CURL_timout} "${URL2}")
		STATE=$(echo $OUT | sed "s/{\"POWER${RELNR}\":\"//g" | sed 's/"}//g' | sed 's/ON/1/g' | sed 's/OFF/0/g')
		echo -e "\tswitch[0|1]: ${STATE}"
		set_CUxD_state $STATE $CHANNEL
	fi
	echo -e "\t[$CHANNEL-status]:    \t$AVAILABLE"
	echo -e "\t[$CHANNEL-ipaddr]:    \t${IPADDR}"
	set_CCU_SysVar $AVAILABLE $CHANNEL-status
	set_CCU_SysVar ${IPADDR} $CHANNEL-ipaddr
}

func_switch_temperature(){
	STATE=0
	if [ $AVAILABLE -ge 1 ] ; then
                if [ -z $APIKEY ] ; then
                        if [ "x$PASSWD" != 'x' ] ; then
                                URL="http://${IPADDR}/cm?user=${USER}&password=${PASSWD}&cmnd=status%2010"
                        else
                                URL="http://${IPADDR}/cm?cmnd=status%2010"
                        fi
			Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
			STATE=$(${CURL} -s ${CURL_timout} "${URL}" | sed -e 's/"//g' -e 's/{//g' -e 's/}//g' | cut -d ',' -f2 | cut -d ':' -f3 )
                else
			URL="http://${IPADDR}/api/temperature?apikey=${APIKEY}"
			Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
			STATE=$(${CURL} -s ${CURL_timout} "${URL}")
		fi
		echo -e "\t[$CHANNEL-temperature]: \t$STATE C"
		set_CCU_SysVar $STATE $CHANNEL-temperature
	fi
}

func_switch_humidity(){
	STATE=0
	if [ $AVAILABLE -ge 1 ] ; then
                if [ -z $APIKEY ] ; then
                        if [ "x$PASSWD" != 'x' ] ; then
                                URL="http://${IPADDR}/cm?user=${USER}&password=${PASSWD}&cmnd=status%2010"
                        else
                                URL="http://${IPADDR}/cm?cmnd=status%2010"
                        fi
                        Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
                        STATE=$(${CURL} -s ${CURL_timout} "${URL}" | sed -e 's/"//g' -e 's/{//g' -e 's/}//g' | cut -d ',' -f3 | cut -d ':' -f2 )
                else
                        URL="http://${IPADDR}/api/humidity?apikey=${APIKEY}"
                        Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
                        STATE=$(${CURL} -s ${CURL_timout} "${URL}")
                fi
		echo -e "\t[$CHANNEL-humidity]: \t$STATE %"
		set_CCU_SysVar $STATE $CHANNEL-humidity
	fi
}

func_switch_power(){
        STATE=0
	TOTAL=0
	YESTERDAY=0
	TODAY=0
	POWER=0
	FACTOR=0
	VOLTAGE=0
	AMPERE=0
        if [ $AVAILABLE -ge 1 ] ; then
                if [ -z $APIKEY ] ; then
                        if [ "x$PASSWD" != 'x' ] ; then
                                URL="http://${IPADDR}/cm?user=${USER}&password=${PASSWD}&cmnd=status%2010"
                        else
                                URL="http://${IPADDR}/cm?cmnd=status%2010"
                        fi
                        Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
                        STATE=$(${CURL} -s ${CURL_timout} "${URL}" | grep -i energy | awk -F'{' '{ print $4 }' | sed -e 's/{//g' -e 's/}//g' -e 's/"//g')
			TOTAL=$(echo $STATE | cut -d, -f1 | cut -d: -f2 )
			TOTAL_EH='kWh'
			TOTAL_VAR='total'
			YESTERDAY=$(echo $STATE | cut -d, -f2 | cut -d: -f2 )
			YESTERDAY_EH='kWh'
			YESTERDAY_VAR='yesterday'
			TODAY=$(echo $STATE | cut -d, -f3 | cut -d: -f2 )
			TODAY_EH='kWh'
			TODAY_VAR='today'
			POWER=$(echo $STATE | cut -d, -f4 | cut -d: -f2 )
			POWER_EH='W'
			POWER_VAR='power'
			FACTOR=$(echo $STATE | cut -d, -f5 | cut -d: -f2 )
			FACTOR_EH=''
			FACTOR_VAR='factor'
			VOLTAGE=$(echo $STATE | cut -d, -f6 | cut -d: -f2 )
			VOLTAGE_VAR='voltage'
			AMPERE=$(echo $STATE | cut -d, -f7 | cut -d: -f2 )
			AMPERE_VAR='ampere'
                else
                        URL="http://${IPADDR}/api/current?apikey=${APIKEY}"
                        Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
                        AMPERE=$(${CURL} -s ${CURL_timout} "${URL}")
			AMPERE_VAR='ampere'
			URL="http://${IPADDR}/api/voltage?apikey=${APIKEY}"
			Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
			VOLTAGE=$(${CURL} -s ${CURL_timout} "${URL}")
			VOLTAGE_VAR='voltage'
			URL="http://${IPADDR}/api/power?apikey=${APIKEY}"
			Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
			POWER=$(${CURL} -s ${CURL_timout} "${URL}")
			POWER_EH='W'
			POWER_VAR='power'
			URL="http://${IPADDR}/api/factor?apikey=${APIKEY}"
			Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
			FACTOR=$(${CURL} -s ${CURL_timout} "${URL}")
			FACTOR_EH='%'
			FACTOR_VAR='factor'
			URL="http://${IPADDR}/api/energy?apikey=${APIKEY}"
			Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
			TOTAL=$(${CURL} -s ${CURL_timout} "${URL}")
			TOTAL_EH='J'
			TOTAL_VAR='energy'
			URL="http://${IPADDR}/api/apparent?apikey=${APIKEY}"
			Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
			YESTERDAY=$(${CURL} -s ${CURL_timout} "${URL}")
			YESTERDAY_EH='W'
			YESTERDAY_VAR='apparent'
			URL="http://${IPADDR}/api/reactive?apikey=${APIKEY}"
			Debugmsg1=$Debugmsg1"func:   \t\t$FUNC\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
			TODAY=$(${CURL} -s ${CURL_timout} "${URL}")
			TODAY_EH='W'
			TODAY_VAR='reactive'
                fi
                echo -e "\t[${CHANNEL}-${TOTAL_VAR}]:    \t$TOTAL $TOTAL_EH"
		echo -e "\t[${CHANNEL}-${YESTERDAY_VAR}]:\t$YESTERDAY $YESTERDAY_EH"
		echo -e "\t[${CHANNEL}-${TODAY_VAR}]:    \t$TODAY $TODAY_EH"
		echo -e "\t[${CHANNEL}-${POWER_VAR}]:    \t$POWER $POWER_EH"
		echo -e "\t[${CHANNEL}-${FACTOR_VAR}]:   \t$FACTOR $FACTOR_EH"
		echo -e "\t[${CHANNEL}-${VOLTAGE_VAR}]:  \t$VOLTAGE V"
		echo -e "\t[${CHANNEL}-${AMPERE_VAR}]:   \t$AMPERE A"
                set_CCU_SysVar $TOTAL $CHANNEL-${TOTAL_VAR}
	       	set_CCU_SysVar $YESTERDAY $CHANNEL-${YESTERDAY_VAR}
		set_CCU_SysVar $TODAY $CHANNEL-${TODAY_VAR}
		set_CCU_SysVar $POWER $CHANNEL-${POWER_VAR}
		set_CCU_SysVar $FACTOR $CHANNEL-${FACTOR_VAR}
		set_CCU_SysVar $VOLTAGE $CHANNEL-voltage
		set_CCU_SysVar $AMPERE $CHANNEL-ampere
       fi
}


case $FUNC in
        "switch")
		checkDevice $IPADDR
		func_switch $1
		;;
	"switch-t")
		checkDevice $IPADDR
		func_switch $1
		func_switch_temperature $1
		;;
	"switch-p")
		checkDevice $IPADDR
		func_switch $1
		func_switch_power $1
		;;
	"switch-th")
		checkDevice $IPADDR
		func_switch $1
		func_switch_temperature $1
		func_switch_humidity $1
		;;
	"status")
		checkDevice $IPADDR
		if [ $AVAILABLE -ge 1 ] ; then
			if [ -z $APIKEY ] ; then
				if [ "x$PASSWD" != 'x' ] ; then
					URL="http://${IPADDR}/cm?user=${USER}&password=${PASSWD}&cmnd=status"
				else
					URL="http://${IPADDR}/cm?&cmnd=status"
				fi
			else
				URL="http://${IPADDR}/apis?apikey=${APIKEY}"
			fi
			Debugmsg1=$Debugmsg1"func:   \t\t$1\ncmd: \t\t${CURL} -s ${CURL_timout} \"${URL}\" \n"
			TEST=$(${CURL} -s ${CURL_timout} "${URL}")
			echo $TEST
		else
			echo -e "api-key or ip-adresse are wrong"
			echo -e "couldn't connect to device\n"
		fi
		;;
	*)
		usage
		exit 1
		;;
esac

if [ $DEBUG -eq 1 ]
then
	echo -e "\n\n"
	echo -e "-----------------------------------------------------------------------------------------------------"
	echo -e "   		               		Debug Ausgaben"
	echo -e "-----------------------------------------------------------------------------------------------------"
	echo -e $Debugmsg1
fi
exit 0
