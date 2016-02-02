#!/bin/bash

#run with ./text_bash_hive_ORC_script_v2.sh <directory_containing_gzipped_files>

#write current  size of hdfs directory to log file
du -s /tmp > tmp_logfile.txt

#readin reference variables list and turn into reference array
getArray() {
    local i=0
    narray=() # Clear array
    while IFS=',' read -r line # Read a line
    do
        HOLD=`echo "$line" | tr ".[]" "___"`
        narray+=( "$HOLD" ) # Append line to the array
    done < "$1"
}


NOT_CREATED_TABLE="true"
DIRECTORY=$1
echo $DIRECTORY
#take user argument for directory and return list of all files in that directory with echo
for entry in $DIRECTORY/*.csv.gz
do
  echo "$entry"
  FILENAME=$entry
  #then we cycle through them gunzipping each one in turn
 echo `du $FILENAME` 
#  no-longer require unzipping
# echo `gunzip $FILENAME`

  #Report File size of zipped and unzipped version
  echo  `du ${FILENAME:0:(-3)}`
  #echo  ${FILENAME:0:(-3)}  

  CSV_NAME=${FILENAME:0:(-3)}
  echo $CSV_NAME

  TABLENAME="temp${FILENAME:(-8):(-7)}"

  #Create appropriate header file to input into hive for table creation
  #du ${FILENAME:0:(-3)} >> tmp_logfile.txt
  #echo "$TABLENAME" >> tmp_logfile.txt

  #FIELDS=`head -1 "${FILENAME:0:(-3)}" |tr ".[]" "___"|sed "s/\t/\n/g" |sed "s/$/ STRING/g"|paste -s -d","`;
  #echo $FIELDS
  #echo "$FIELDS" > ~/fields_list.txt

  FIELDS=`cat ~/fields_list.txt`
  echo "Fields are:"
  echo "$FIELDS"
  NEWFIELDS=""

  #now we cycle through fields an convert non-STRING variables to those listed in variable_types.txt
  #turns string into an aray dellimited by ,
  IFS=',' read -r -a array <<< "$FIELDS"	
  for f in "${array[@]}"
  do
   #splits row of array by whitespace characters
   arrIN=(${f// / })
   #set default output type to be STRING
   OUT="${arrIN[1]}" 
   #then  cycle through the input file to check if it's a non-string variable 
   getArray "variable_types.txt"
   for e in "${narray[@]}"
   do
     narrIN=(${e//,/ })
     #echo "${narrIN[0]}"
     if [ "${narrIN[0]}" = "${arrIN[0]}" ]; then
  	  OUT="${narrIN[1]}"
	  echo $OUT
     fi
   done 
   #     #|tr '[:lower:]' '[:upper:]' 
   NEWFIELDS="${NEWFIELDS}${arrIN[0]} ${OUT},"
  done

  COMMAND_STRING="CREATE TABLE mlab.${TABLENAME} (${NEWFIELDS:0:(-1)}) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' TBLPROPERTIES('skip.header.line.count'='1');"
  echo "${COMMAND_STRING}" > ~/create-table.txt

  STARTTIME=`date +"%s"` 
  #date +"%s ">> tmp_logfile.txt

  #hive commands 
  #echo `hive -e "Use Mlab; ${COMMAND_STRING}; LOAD DATA LOCAL INPATH '${CSV_NAME}' INTO TABLE mlab.${TABLENAME};"`
  #hive command using beeline rather than hive CLI
  echo `beeline -u jdbc:hive2:// -e "Use Mlab; ${COMMAND_STRING}; LOAD DATA LOCAL INPATH '${FILENAME}' INTO TABLE mlab.${TABLENAME};"`

  #maximum hdfs filesize
  du -s /tmp >> tmp_logfile.txt

  #formatting as parquet
  #PAR_COMMAND_STRING="CREATE TABLE mlab.${TABLENAME}_par (${FIELDS}) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' STORED AS PARQUET TBLPROPERTIES('skip.header.line.count'='1');"

  #format for the above but using single table
  PAR_COMMAND_STRING="CREATE TABLE mlab.temp_paro (${FIELDS}) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' STORED AS orc TBLPROPERTIES('orc.compress.size'='8192', 'orc.compress'='SNAPPY' ,'skip.header.linder.line.count'='1');"

  #if the temp_par table doesn't exist we must create it
  if [ "$NOT_CREATED_TABLE" == "true" ]; then
       #now we attempt to put everything inb ONE table rather than creating new parquet tables for each day
       echo `beeline -u jdbc:hive2:// -e "Use Mlab; ${PAR_COMMAND_STRING}; INSERT INTO TABLE mlab.temp_paro SELECT * from mlab.${TABLENAME};"`
       echo "Table Created"
       NOT_CREATED_TABLE="false"
  else
       echo `beeline -u jdbc:hive2:// -e "Use Mlab; INSERT INTO TABLE mlab.temp_paro SELECT * from mlab.${TABLENAME};"`
       echo  "Table appended"
  fi

  #remove original csv table
  #echo `hive -e "Use Mlab; DROP TABLE mlab.${TABLENAME};"`
  #now using beeline instead of hive CLI
  echo `beeline -u jdbc:hive2:// -e "Use Mlab; DROP TABLE mlab.${TABLENAME};"`

  #Loadin data time
  ENDTIME=`date +"%s"` 
  #date  +"%s" >> tmp_logfile.txt

  #readin new size of /tmp file size
  #du ${FILENAME:0:(-3)} >> tmp_logfile.txt
  #$TABLENAME >> tmp_logfile.txt
  expr $ENDTIME - $STARTTIME >> tmp_logfile.txt
  du -s /tmp >> tmp_logfile.txt

  #Remove original csv file (.gz file removed by gunzip)
#  echo `rm ${FILENAME}`
done
