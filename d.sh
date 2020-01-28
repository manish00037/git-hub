#/bin/sh
i=`nsu_show_netstorm|head -n 2|tail -n -1|cut -d ' ' -f 1`
#read  mon
mon=$1
cd $NS_WDIR/logs/TR$i;

tier=$2
p=`cat .curPartition |head -n 2|tail -n -1|cut -d '=' -f 2`
cd $p
echo "which monitor and tier ?"
gdf=`grep -w $mon /home/cavisson/work/etc/standard_monitors.dat|cut -d "|" -f 2`
prog=`grep -w $mon /home/cavisson/work/etc/standard_monitors.dat|cut -d "|" -f 4`
date
echo $mon $gdf $prog

#read tier
grep -E "cm_partition_switch|Connection established|Sending msg 'cm_init_monitor|Connection closed" monitor.log|grep  $gdf:$tier  >/tmp/log/mon.log
date

if grep "cm_partition_switch" /tmp/log/mon.log >/dev/null
then
port=`grep -Po '(?<=IPV4:)(\S+)' /tmp/log/mon.log|cut -d '.' -f5|cut -d"'" -f1`
infs=`ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)'`
#tcpdump -A -i $infs port $port >/tmp/log/tcpdump$port
sudo netstat -natp |grep $port  >/tmp/log/netstat
unset port
elif grep "Connection established" /tmp/log/mon.log >/dev/null
then 
echo "upto elif block"
sleep 10
port=`grep "Connection established" /tmp/log/mon.log|grep -Po '(?<=IPV4:)(\S+)'|tail -n 1|cut -d '.' -f5|cut -d"'" -f1`
echo "port is $port"
sudo netstat -natp |grep -w $port  >/tmp/log/netstat
opts=`cat /tmp/log/mon.log|grep cm_init |tail -n 1|cut -d ";" -f 7 |cut -d " " -f5-14`
Sip=`grep "establi" /tmp/log/mon.log|tail -n 1|grep -Po "(?<=destination address \')(\S+)"|cut -d ":" -f1`
nsu_server_admin -s $Sip -v >/tmp/log/serverlog
if grep "MON_PGM_NAME=java" /tmp/log/mon.log >/dev/null
then 
echo "java monitor"
nsu_server_admin -s $Sip -S >>/tmp/log/serverlog
mhome=`grep -Po "(?<=-DPKG=cmon )(\S+)" /tmp/log/serverlog`
jars=`grep -Po "(?<=-DCLASSPATH=)(\S+)" /tmp/log/serverlog`
mapname=`nsu_server_admin -s $Sip -c 'cat MonitorMapping.properties' |grep -Po "(?<=$prog = )(\S+)"`
args=`echo "-c 'java $mhome -cp $jars $mapname $opts'"`
echo $args
nsu_server_admin -s $Sip $args
else 
echo "Shell bashed monitor"
nsu_server_admin -s $Sip -c"$prog $opts"
fi
else
echo 
echo UNIX does not occur in /tmp/lo
fi

