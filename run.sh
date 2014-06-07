#!/bin/bash
if [ "$NERVE_APP" == "" ];then
  echo "NERVE_APP environment variable must be set" >&2
  exit 1
fi
if [ "$NERVE_INSTANCE" == "" ];then
  NERVE_INSTANCE=$(hostname --fqdn) # Container #ID
#  echo "NERVE_INSTANCE environment variable must be set" >&2
#  exit 1
fi
PINGOUT=$(ping -c 1 -i 0 etcd 2>&1);
PINGSTATUS=$?
if [ $PINGSTATUS != 0 ];then
  echo "WARNING: Cannot find host named 'etcd', you need to link an etcd container to this container!" >&2
  echo "$PINGOUT" >&2
  exit 2
fi

sed -i -e"s/%%INSTANCE_ID%%/${NERVE_INSTANCE}/" /nerve.conf.json
env|egrep '\w+_PORT=tcp://'|sed -e's/\(.*\)_PORT=tcp:../\1:/'|ruby1.9.3 -e'require "json";NERVE_APP=ENV["NERVE_APP"];STDIN.each_line {|l| d=l.chomp.split(/:/); File.open("/nerve_services/#{d[0]}.json", "w") {|f| f.puts Hash["host",d[1],"port",d[2],"reporter_type","etcd","etcd_host",ENV["ETCD_PORT_4001_TCP_ADDR"],"etcd_port",ENV["ETCD_PORT_4001_TCP_PORT"].to_i,"etcd_path","/nerve/services/#{NERVE_APP}/services","check_interval",2,"checks",[Hash["type","tcp","timeout",0.2,"rise",3,"fall",2]]].to_json}}'
rm -f /nerve_services/ETCD.json

SERVICECOUNT=$(ls /nerve_services | wc -l)
if [ $SERVICECOUNT == 0 ];then
  echo "WARNING: No services found, did you link any containers to this one?"
fi

# Default argument
if [ "$1" == "run" ];then
  if [ $PINGSTATUS != 0 ];then
    echo "Shelling out as setup failed"
    exec /bin/bash
  fi
  exec /usr/local/bin/nerve -c /nerve.conf.json
fi

# Anything else :)
eval "$*"

