#How to install Hive onto an Ubuntu server cluster and import Mlab data.

This tutorial should take you through step-by-step instructions for creating a Hive cluster capable of running queries on a month of Mlab data in a matter of minutes on a couple of reasonable boxes.

The general outline is:

1. Install Ubuntu Server 14.04.3 on each box.

2. Get Hadoop

3. Get Hive and connect to Hadoop

4. Create tables and populate with data from Mlab.csv

5. Run SQL queries

6. ...

7. Profit!

##Ubuntu Server install
Create a bootable flashdrive with Ubuntu Server 14.04.3 on it (iso downloaded from: http://www.ubuntu.com/download/server) and use it to install on all nodes.
We used unetbootin on OSX to create the bootable stick but highly recommend using any other method that you can (i.e. ```dd```). However remember you must also make the disk bootable and make an active partition in order for it to act as a boot disk.

For the purposes of this tutorial we have an admin user with the name 'bambi'.
Replace this with the username of your use in the commands and code below.

##Setting Master and slves on all machines
On all machines ip addresses and associated names must be set in the following file
```sudo nano /etc/hosts```

An example from a two machine cluster (master and slave1) is included below
   127.0.0.1 localhost
   127.0.1.1 <machinename>
   
   130.195.248.39 master
   130.195.248.76 slave1

##Setting master login permissions
The master must be able to login to itself via ssh and to all other nodes without passwords. 
Check ```ssh master``` from the master logs in without password and is in the known hosts list.
Check master can login to slave using ```ssh slave1```. 
You will need to add the master’s public SSH key to the slave’s authorized_keys file:
bambi@master$ ssh-copy-id -i $HOME/.ssh/id_rsa.pub bambi@slave1 
and if you haven’t done it before also generate the public SSH key on the master first
```ssh-keygen -t rsa -P "" ```

##Hadoop install
Run the following ubuntu commands in the terminal:
```sudo apt-get update```

```sudo apt-get upgrade```

```sudo apt-get install ssh rsync git```

```sudo apt-get install openjdk-7-jdk```

We also recommend the following for debugging:
```sudo apt-get install nmap```

Hadoop can be downloaded by running:
```wget http://www.eu.apache.org/dist/hadoop/common/hadoop-2.7.1/hadoop-2.7.1.tar.gz```
Unzip
```sudo tar xzf hadoop-2.7.1.tar.gz```
Change permissions
```sudo chown -R bambi hadoop-2.7.1```
Move into directory
```cd hadoop-2.7.1```
Set root of java installation by editing etc/hadoop/hadoop-env.sh 
```sudo nano etc/hadoop/hadoop-env.sh```
Then update the following lines
    # set to the root of your Java installation
    export JAVA_HOME=/usr

Now execute hadoop to check everything downloaded ok
``` bin\hadoop ```

We followed the file setup rocedures outlined [here](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html#Pseudo-Distributed_Operation) but in summary they are:
1. Edit etc/hadoop/slaves with ```sudo nano etc/hadoop/slaves``` and includes all nodes with datanodes to be run on them.
Originally we included the master in this but once we had sufficient datanodes we removed it so that it was only acting as the jobtracker.
2. Edit etc/hadoop/core-site.xml with the location of the core HDFS site (i.e. the ip address and port of the master).
   <configuration>
      <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
      </property>
      <description>The name of the default file system.  A URI whose
     scheme and authority determine the FileSystem implementation.  The
     uri's scheme determines the config property (fs.SCHEME.impl) naming
     the FileSystem implementation class.  The uri's authority is used to
     determine the host, port, etc. for a filesystem.</description>
   </configuration>
On the master this should be localhost:9000. on all slaves it should be set to master:9000 
3. Set the degree of replicaiton of the data (for testing set to 1 but realistically increase to 2 at least for proper distibuted operation.)
   <configuration>
      <property>
        <name>dfs.replication</name>
        <value>1</value>
      </property>
      <description>Default block replication.
     The actual number of replications can be specified when the file is created.
     The default is used if replication is not specified in create time.</description>
   </configuration>
4. Edit etc/hadoop/mapred-site.xml with ```sudo nano etc/hadoop/mapred-site.xml```
   <property>
     <name>mapred.job.tracker</name>
     <value>master:54311</value>
      <description>The host and port that the MapReduce job tracker runs
      at.  If "local", then jobs are run in-process as a single map
      and reduce task.</description>
   </property>

More hadoop configuration parameters can be set in these files. They are discussed in some detail [here](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html) and [here](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1.10/bk_installing_manually_book/content/rpm-chap1-11.html) but we recommend sticking with the defaults until the cluster is running and then upgrading from there.

##Creating and Running Hadoop Distributed File System (HDFS) on the master.
You can start and stop the entire cluster using this command once slave nodes have been setup. 
First we must format the namenode of the hdfs by running the following from within the hadoop root directory (hadoop-2.7.1 in my example above)
```bin/hdfs namenode -format```
Then the hdfs can be started and stopped by the following two commands respectively
```sbin/start-dfs.sh``` and ```sbin/stop-dfs.sh```

After starting the HDFS you can check if it is running as expected by running ```jps``` or ```top``` from the command line. 
```jps``` should give you a list of primary and secondary namenodes, a jobtracker and a datanode process. If any of these are missing try stoppong and startong the hdfs. If that doesn't work you will likely need to format your namenode again (but DON'T do it whilst your HDFS is running or you will erase all of the data on it).
Yes I learnt that the hard way.

##Creating Hive directory structure
On the master machine create the following directory structures from the root hadoop directory. This process does NOT need to be repeated on slave machines.

```bin/hadoop fs -mkdir /tmp```

```bin/hadoop fs -mkdir /user ```

```bin/hadoop fs -mkdir /user/bambi```

```bin/hadoop fs -mkdir /user/bambi/warehouse```

```bin/hadoop fs -chmod g+w   /tmp```

```bin/hadoop fs -chmod g+w   /user/bambi```

```bin/hadoop fs -chmod g+w   /user/bambi/warehouse```

If at any stage your datanode becomes corrupted you can erase the entire thing by:

``` bin/stop-all.sh ```

```rm -Rf /tmp/hadoop-username/\*```  (NOT /tmp\*)

```bin/hdfs namenode -format ```

####DON'T DO THIS UNLESS YOU HAVE NO OTHER CHOICE.

##Acquiring Hive
Grab Hive by the following commands:

```wget http://www.us.apache.org/dist/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz ```

```sudo tar -xzvf apache-hive-1.2.1-bin.tar.gz ```

```sudo chown -R bambi apache-hive-1.2.1-bin ```

##Setting up environmental variables and appending to $PATH
``` nano ~/.bashrc ```
And append the following lines to the bottom of the file:

    export HIVE_HOME=/home/fogbank/apache-hive-1.2.1-bin/
    export HADOOP_HOME=/home/fogbank/hadoop-2.7.1
    export PATH=$HIVE_HOME/bin:$PATH
    export PATH=$HADOOP_HOME/bin:$PATH
   
Now reload the environmental variables using:
```source ~/.bashrc```

You can check the previous commands by using something along the lines of:
```echo $HADOOP_HOME```

##The Hive CLI (Beeline and Hiverserver2)

To actually run SQL queries we simply use the following (once the HDFS has already been started)
```beeline -u jdbc:hive2://```

##Hive database and table creation and deletion commands
Select a specific database to use with:
```hive> use mlab;```

Creating a table (called pokes with the fields foo and bar) is now simple using SQL syntax:
```hive> CREATE TABLE pokes (foo INT, bar STRING);```

Tables can be displayed using:
```hive> SHOW TABLES;```

Tables can be deleted by:
```hive> DROP TABLE pokes;```

##Performance and data storage
Mlab data can be uploaded and stored as strings in csv format, however this leads to poor performance (about 3 minutes for a simple count query and requiring 19 GB of disk space to store one month of Mlab data).
Instead we recommend filtering data by the fields outlined at and storing the data as compressed ORC, a columnar file storage system. (Parquet can also be used but ORC gives faster performance and uses less disk space)
With the environmental variable $FIELDS set to the field headers stripped from the mlab data, the following will create a table (temp_orc) using the appropriate compression and storage type:

```CREATE TABLE mlab.temp_orc (${FIELDS}) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' STORED AS ORC TBLPROPERTIES('orc.compress.size'='8192', 'orc.compress'='SNAPPY','skip.header.linder.line.count'='1');```

PLease note that if you store as ORC with compression - using the default (or otherwise incorrect compression numbers can result in queries failing). 
If you suspect this, attempt to create an 'uncompressed' ORC table.
With current compression ORC can store 19GB (roughly a month) of mlab data in 570 MB of disk space and run a simple query on it in between 5-7 seconds.
The same data in Parquet requires 890 MB of space and a query takes 6-9 seconds to run.

N.B. The default for compression size is 262,144 (as stated here:https://orc.apache.org/docs/hive-config.html)
There’s a chance we could improve storage and performance further by increasing the compression size as close as possible to the default value.

##Scripts
I have included some bash scripts to create the tables above and then populate them with .gzipped Mlab data files.
Check the repositories for the latest versions.


Next Steps:
- [ ] Upgrade backend from Mapreduce to Tez.
- [ ] Check performance gains by increasing compression chunk size closer to default value.
- [ ] Setup machine image for cloning nodes (instead of doing an install by hand each time). 
- [ ] Replace unetbootin with functional dd commands.
- [ ] Run more tests on more machines an check scaling performace.
- [ ] Test performance on join queries.
- [ ] Write tutorials for the same process for WEKA (Machine Learning) and GERRIS (fluid modelling)
