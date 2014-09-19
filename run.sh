#!/bin/bash
if [ "$NERVE_APP" == "" ];then
  echo "NERVE_APP environment variable must be set" >&2
  exit 1
fi
if [ "$NERVE_INSTANCE" == "" ];then
  NERVE_INSTANCE=$(hostname --fqdn) # Container #ID
fi
if [ "$ZK_PORT_2181_TCP_ADDR" == "" ];then
  echo "Cannot find ZK_PORT_2181_TCP_ADDR variable, you need to link an ZK container to this container!" >&2
  exit 2
fi
if [ "$ZK_PORT_2181_TCP_PORT" == "" ];then
  ZK_PORT_2181_TCP_PORT=2181
fi

sed -i -e"s/%%INSTANCE_ID%%/${NERVE_INSTANCE}/" /nerve.conf.json
#Consider starting with json file for upload
#env|egrep '\w+_PORT=tcp://'|sed -e's/\(.*\)_PORT=tcp:../\1:/'|ruby1.9.3 -e'require "json";NERVE_APP=ENV["NERVE_APP"];STDIN.each_line {|l| d=l.chomp.split(/:/); File.open("/nerve_services/#{d[0]}.json", "w") {|f| f.puts Hash["host",d[1],"port",d[2],"reporter_type","zookeeper","zk_hosts",[ENV["ZK_PORT_2181_TCP"]],"zk_path","/nerve/services/#{NERVE_APP}/services","check_interval",2,"checks",[Hash["type","tcp","timeout",0.2,"rise",3,"fall",2]]].to_json}}'
env|egrep 'SMARTSTACK.+TCP='|sed -e's/\(.*\)_PORT_.*\_TCP=tcp:../\1:/'|ruby1.9.3 -e'
require "json";

NERVE_APP=ENV["NERVE_APP"];

STDIN.each_line {|l| d=l.chomp.split(/:/);
File.open("/nerve_services/#{d[0]}.json", "w") {
	|f| f.puts Hash["host",d[1],
	"port",d[2],
	"reporter_type","zookeeper",
	"zk_hosts", [ ENV["ZK_PORT_2181_TCP"] ],
	"zk_path",	"/nerve/services/#{NERVE_APP}/services",
	"check_interval",2,
	"checks",[Hash["type","http",
		"uri",d[1],
		"port",d[2],
		"timeout",0.2,
		"rise",3,
		"fall",2]]].to_json
	#{}"checks",[Hash["type","tcp","timeout",0.2,"rise",3,"fall",2]]].to_json
}
}'

rm -f /nerve_services/ZK.json

SERVICECOUNT=$(ls /nerve_services | wc -l)
if [ $SERVICECOUNT == 0 ];then
  echo "WARNING: No services found, did you link any containers to this one?"
fi

# Default argument
if [ "$1" == "run" ];then
  exec /usr/local/bin/nerve -c /nerve.conf.json
fi

# Anything else :)
eval "$*"

