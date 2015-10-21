#M-lab Data

This document is intended to bring the reader up to speed with current state of m-lab data through both BigQuery command line interface (or Web Query) and Raw Data.
It is up to date as of October 2015 (unlike the core Mlab documentation (https://github.com/m-lab/mlab-wikis/blob/master/HowToAccessMLabData.md) which apppears not have been updated since 2010).

##BigQuery 
Once you have commandline `bq` you have read acess to the public Mlab datasets and tables (but not the data itself)

###Mlab BigQuery Datasets
The command `bq ls measurement-lab:` current shows the following two datasets:
```
  datasetId  
 ----------- 
  ic2012     
  m_lab      
```

###Mlab BiqQuery Tables
The command `bq ls measurement-lab:m_lab` now shows the following:
```
             tableId             Type   
 ----------------------------- ------- 
  All_IP_addresses              TABLE  
  TestSliceIpAdresses           TABLE  
  congsignal_kr_201212          TABLE  
  congsignal_kr_201212_2        TABLE  
  hops_lga01_2013_09            TABLE  
  lga01_comcast_rtt             TABLE  
  lga02_cogent_to_comcast_hop   TABLE  
  ndt_tests_per_day_per_ip      VIEW   
  nl_2014_05                    TABLE  
  nz_all                        TABLE  
```
`bq show measurement-lab:m_lab.ndt_tests_per_day_per_ip` then shows something like:
```
   Last modified            Schema            Type   Expiration  
 ----------------- ------------------------- ------ ------------ 
  06 Aug 14:34:40   |- num_tests: integer     VIEW               
                    |- num_clients: integer 
```

Whilst the filestructure can be browsed, attempts to query the data itself currently fail without permission of the mlab team yielding:
```
BigQuery error in query operation: Error processing job
'<project_name>:bqjob_r7ff843dc1ce26f57_0000015087e97db4_1': Access Denied: Project
<project_name>: Linked tables are deprecated and cannot be queried by this project.
Contact the table owner for more information.
```

##Raw data

The description of the raw data available online or through gsutil available here: https://github.com/m-lab/mlab-wikis/blob/master/HowToAccessMLabData.md is still accurate

###NDT
NDT data is described in multiple sources online, however the files generated as a result are not.
In general, the Mlab NDT data available here: https://console.developers.google.com/storage/browser/m-lab/ndt/
is sorted by year, month, day and then by server allocation (e.g. mlab1-sin1).
Within that tarball (`tar -xzf <tarball_name>.tgz`) are sets of files for each test run by that server:

* a .meta (metadata file)
* a cputime file (I currently have no idea what this is.)
* a .s2c_snaplog 
* a .c2s_snaplog 
* a .s2c_ndttrace (full server to client packet trace) *Optional*
* a .c2s_ndttrace(full client to server packet trace) *Optional*

####Meta file
The .meta file contains the following fields:
* Date/Time: 
* c2s_snaplog file: 
* c2s_ndttrace file: 
* s2c_snaplog file: 
* s2c_ndttrace file: 
* cputime file: 
* server IP address: 
* server hostname: mlab1.sin01.measurement-lab.org
* server kernel version: 
* client IP address: 
* client hostname: 
* client OS name: 
* client_browser name:
* client_application name: 
* Summary data: 
* Additional data:
* client.os.name: 
* client.browser.name: 
* client.kernel.version:
* client.version: 
* client.utorrent.version: 

####.s2c_snaplog/.c2s_snaplog 
These file contain a header of the form: `2.5.27 201001301335 net100` 

Followed by `/spec`,`/read`, `/tune` fields and then: `----Begin-Snap-Data----`
Each entry in the `/spec`, `/read` and `\tune` corresponds to a Web100 field and variables listed in full here:
https://cloud.google.com/bigquery/docs/tcp-kis.txt.

I suggest `head -n 168 filename.s2c_snaplog` if you want the entire header and anytime beyond that for the testfile to start speaking in tongues.

The relevant fields the Mlab team seems to use in much of their visualizations are (in no particular order):
* [Download Throughput](https://github.com/m-lab/mlab-wikis/blob/master/PDEChartsNDT.md#download-throughput)
* [Network-limited time ratio](https://github.com/m-lab/mlab-wikis/blob/master/PDEChartsNDT.md#network-limited-ratio-and-client-limited-time-ratio)
* [Number of tests](https://github.com/m-lab/mlab-wikis/blob/master/PDEChartsNDT.md#number-of-tests)
* [Packet Retransmission](https://github.com/m-lab/mlab-wikis/blob/master/PDEChartsNDT.md#packet-retransmission)
* [Percentage of Tests in Congestion Avoidance](https://github.com/m-lab/mlab-wikis/blob/master/PDEChartsNDT.md#percentage-of-tests-that-reached-congestion)
* [Reciever Window Scale](https://github.com/m-lab/mlab-wikis/blob/master/PDEChartsNDT.md#receiver-window-scale)
* [Reciever-limited time ratio](https://github.com/m-lab/mlab-wikis/blob/master/PDEChartsNDT.md#network-limited-ratio-and-client-limited-time-ratio)
* [Round Trip Time](https://github.com/m-lab/mlab-wikis/blob/master/PDEChartsNDT.md#round-trip-time-rtt)
* [Upload Throughput](https://github.com/m-lab/mlab-wikis/blob/master/PDEChartsNDT.md#upload-throughput)
Oh and the visualizations I'm talking about are available online here [here](http://www.google.com/publicdata/explore?ds=e9krd11m38onf_&ctype=m&strail=false&bcs=d&nselm=s&met_s=number_of_tests&scale_s=lin&ind_s=false&ifdim=country&hl=en_US&dl=en_US&ind=false&xMax=180&xMin=-180&yMax=-54.423985288271695&yMin=81.24033645136825&mapType=t&icfg&iconSize=0.5#!ctype=m&strail=false&bcs=d&nselm=s&met_s=rtt&scale_s=lin&ind_s=false&ifdim=country&hl=en_US&dl=en_US&ind=false) and are pretty well....pretty.
Finally they also kindly specify how they calculate each of their metrics (in BigQuery syntax rather than from the raw data but they're comparable at least) [here](https://github.com/m-lab/mlab-wikis/blob/master/PDEChartsNDT.md).

####Cputime
A series of 0.1s timesteps followed by 4 int columns e.g.:
* 0.00 0 0 0 0
* 0.10 0 0 0 0
* etc
No idea what these signify currently.
