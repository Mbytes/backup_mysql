#!/bin/sh

#Reparar Tablas BBDD y volcados MySql

DUMP=/home/dump_mysql

HOST=$(cat /etc/hostname | sed 's/\(.*\)/\U\1/')

#Prefijo Tablas
PREFIX=${HOST}

#Ficheros temporales
TEMPTABLES=/tmp/databases.sql
TMPRUN=/tmp/tablesrepair.sh
TMPDUMP=/tmp/dumpdatabases.sh
TMPALLRUN=/tmp/ALLtablesrepair.sh

USER=$(cat /etc/mysql/debian.cnf | grep ^user | tail -1 | awk '{print $3}')
PWD=$(cat /etc/mysql/debian.cnf | grep ^password | tail -1 | awk '{print $3}')

FECHA=$(date +%Y%m%d)


#Funcion de tablas por base datos
#RepairBBDD BASE_DATOS TABLAS
RepairBBDD ()
{
	echo "Reparando $1 "
	cat $2 | awk '{print "repair table " $1 ";"}' | mysql -u$USER -p$PWD "$1" 
} #EndFunction



#Listamos BBDD
echo show databases | mysql -u$USER -p$PWD | grep -v Database > ${TEMPTABLES} 


#Listado de Tablas por BBDD
cat ${TEMPTABLES} | awk -v USER=$USER -v PWD=$PWD '{print "echo show tables | mysql -u" USER " -p" PWD " \"" $1 "\" |grep -v Tables_in  > /tmp/repair." $1 ".sql"  }' > ${TMPRUN}
sh ${TMPRUN}

#Procesamos reparar Tablas de cada BBDD
while read  BBDD
do
#	echo "Reparando...  ${BBDD}"
	RepairBBDD "${BBDD}" /tmp/repair.${BBDD}.sql
done < ${TEMPTABLES}


#Borramos viejos
rm ${DUMP}/*sql

#Realizamos volcados datos
cat ${TEMPTABLES} | awk -v DUMP=${DUMP} -v USER=$USER -v PWD=$PWD -v FECHA=$FECHA -v PREFIX=$PREFIX '{print "mysqldump --compact --insert-ignore --single-transaction -hlocalhost -u" USER " -p" PWD " --quote-names " $1 " -r " DUMP "/" PREFIX "_" $1 "_" FECHA ".sql" }' > ${TMPDUMP}
sh ${TMPDUMP}

#Realizamos volcados structuras
cat ${TEMPTABLES} | awk -v DUMP=${DUMP} -v USER=$USER -v PWD=$PWD -v FECHA=$FECHA -v PREFIX=$PREFIX '{print "mysqldump -d -hlocalhost -u" USER " -p" PWD " --quote-names " $1" -r " DUMP "/" PREFIX "_STRUCT_" $1 "_" FECHA ".sql" }' > ${TMPDUMP}
sh ${TMPDUMP}




##Borrado Final
exit
