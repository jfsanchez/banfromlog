#!/bin/bash

#
# banfromlog: examines logs to prevent ssh brute force attacks
#    and forbids ips with many attempts to connect to your host at 22 port.
# Copyright (C) 2005 Jose Sanchez <jose_at_serhost_dot_com> http://serhost.com

# Specials thanks to: Julio Mendoza
# julio_dot_mendoza_at_eemsystems_dot_com  - http://eemsystems.com/
# who suggest the sqlite compatibility and programmed almost all sqlite compatibility

# This script was based on another one from: http://tuxworld.homelinux.org
# In this version you hardly can find a line from them.

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA


#CONFIGURE THE FOLLOWING PARAMETERS BEFORE USING THIS SCRIPT

#In future versions this script will be adapted for using another systems different from iptables
IPTABLES="/sbin/iptables"	# path of iptables
SSHPORT="22"			# The port of your SSHD server (default 22).
LOGFILE="/var/log/auth.log"	# log file path
DBtype="sqlite"			# MySQL or sqlite
#Field only needed if you use sqlite
sqlitebin="sqlite3"		# path of the binary of sqlite
#Fields only needed if you use MySQL
sql_host="localhost"		# Hostname of the SQL server
sql_user="sqluser"		# Username of the SQL server
sql_pass="sqlpassword"		# Password of the SQL username to connect the database
sql_db_name="firewall"		# Name of the SQL database

# Remove or comment this two lines AFTER CONFIGURING this script
#echo "Configure me first!. Edit me and remove this comment to use me"
#exit 0;
#************************************************

case "$1" in

	log2db)
		#Future modification: Only log an ip after 10 different illegal users.
		# Now forbids even an only illegal user

		if [ $DBtype == "sqlite" ]; then
			if [ ! -s ./firewall.db3 ]; then
				echo "First execution. Creating sqlite DB..."
				$sqlitebin ./firewall.db3 "CREATE TABLE blacklist (ip varchar(50) NOT NULL unique,comment varchar(250));"
			fi
			#sqlite
			db_exist=`$sqlitebin ./firewall.db3  "SELECT ip FROM blacklist "`;
		else
			#MySQL
			db_exist=`mysql -D $sql_db_name -B -h $sql_host -e "SELECT ip FROM blacklist " -u $sql_user --password=$sql_pass`;
		fi
		echo 
		echo "Logging..."
		echo
		o=0

		datum=`date`

		for i in `cat $LOGFILE|grep Illegal|awk '{print $10}'|sort -n|uniq|awk 'BEGIN{ FS=":"}; { print $4}'`
		do

			search=`echo $db_exist | grep "$i" |  awk 'BEGIN{ FS=" " }; { print $1 }' `;
			if [ ! $search ]
			then
				if [ $DBtype == "sqlite" ]; then
					$sqlitebin ./firewall.db3 "INSERT INTO blacklist ( ip, comment ) VALUES ( \" $i \", \"ssh_bruteforce, $datum \" )";
				else
					mysql -u $sql_user --password=$sql_pass -D $sql_db_name -B -h $sql_host -e "INSERT INTO blacklist ( ip, comment ) VALUES ( \" $i \", \"ssh_bruteforce, $datum \" )";
				fi
				db_exist="$db_exist $i";
				echo "Logging: $i"
				((o=o+1))
			fi

		done

		echo "Finished. Added $o new ip(s) to the firewall"
		echo
	;;

	protect)
		#IMPORTANT: Don't forbid internal networks
		if [ $DBtype == "sqlite" ]; then
			sql_blacklist=`$sqlitebin ./firewall.db3 "SELECT ip FROM blacklist WHERE ip not like '192.168.%%' and ip not like '10.%%' and ip not like '172.%%'"`;
		else
			sql_blacklist=`mysql -D $sql_db_name -h $sql_host -u $sql_user --password=$sql_pass -B -e "SELECT ip FROM blacklist WHERE ip not like '192.168.%%' and ip not like '10.%%' and ip not like '172.%%'"`;
		fi

		for i in `echo $sql_blacklist`
		do
			if [ $i != "ip" ]; then 
				$IPTABLES -I INPUT -p tcp --dport $SSHPORT -s $i -j DROP
				#echo "Access from: $i is forbidden";
			fi
		done
	;;


	show)
		#Only show invalid attempts with an invalid user
		cat $LOGFILE|grep Illegal|awk '{print $10}'|sort -n|uniq|awk 'BEGIN{ FS=":"}; { print $4}'
	;;

	html)
		#Special thanks to Dr. Joan de Gracia - <jdega25 at yahoo dot es> for the idea
		if [ $DBtype == "sqlite" ]; then
			sql_blacklist=`$sqlitebin ./firewall.db3 "SELECT ip FROM blacklist WHERE ip not like '192.168.%%' and ip not like '10.%%' and ip not like '172.%%'"`;
		else
			sql_blacklist=`mysql -D $sql_db_name -h $sql_host -u $sql_user --password=$sql_pass -B -e "SELECT ip FROM blacklist WHERE ip not like '192.168.%%' and ip not like '10.%%' and ip not like '172.%%'"`;
		fi

		echo "<pre>"

		for i in `echo $sql_blacklist`
		do
			if [ $i != "ip" ]; then 
				echo $i
			fi
		done

		echo "</pre>"
	;;

	*)
		echo 
		echo "Banfromlog comes with ABSOLUTELY NO WARRANTY"
		echo "This is free software, and you are welcome to redistribute it"
		echo "under certain conditions. Edit this file in order to see the license"
		echo 
		echo "BanFromLog: Examine log and generate a firewall"
		echo "Copyright (C) 2005 Jose Sanchez <jose_at_serhost_dot_com>"
		echo 
		echo "USE: banfromlog log2db     <--- Logs illegal users to the DB (sqlite or MySQL)"
		echo "     banfromlog protect    <--- Executes the iptables rules to protect your host"
		echo "     banfromlog show       <--- Shows attacks from the ACTUAL log"
		echo "     banfromlog html       <--- Shows logged ips in html format (<pre></pre>)"
		echo
	;;

esac

exit 0

# banfromlog 0.75  - - -  24 Feb 2006 
# Jose Sanchez (C) 2005 - http://serhost.com
#   <jose_at_serhost_dot_com>
