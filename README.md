#M-lab Data

This document is intended to bring the reader up to speed with current state of m-lab data through both BigQuery command line interface (or Web Query) and Raw Data.
It is up to date as of October 2015 (unlike the core Mlab documentation (https://github.com/m-lab/mlab-wikis/blob/master/HowToAccessMLabData.md) which apppears not have been updated since 2010).

##BigQuery 
Once you have commandline 'bq' the command 'bq ls measurement-lab:m_lab' now shows the following:
'''
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
'''
'bq show measurement-lab:m_lab.ndt_tests_per_day_per_ip' then shows something like:
'''
   Last modified            Schema            Type   Expiration  
 ----------------- ------------------------- ------ ------------ 
  06 Aug 14:34:40   |- num_tests: integer     VIEW               
                    |- num_clients: integer 
'''

Whilst the filestructure can be browsed, attempts to query the data itself currently fail without permission of the mlab team yielding:
'''
BigQuery error in query operation: Error processing job
'<project_name>:bqjob_r7ff843dc1ce26f57_0000015087e97db4_1': Access Denied: Project
<project_name>: Linked tables are deprecated and cannot be queried by this project.
Contact the table owner for more information.
'''

##Raw data

The description of the raw data available online or through gsutil available here: https://github.com/m-lab/mlab-wikis/blob/master/HowToAccessMLabData.md is still accurate

###NDT
NDT data is described in multiple sources online, however the files generated as a result are not.
In general, the Mlab NDT data available here: https://console.developers.google.com/storage/browser/m-lab/ndt/
is sorted by year, month, day and then by server allocation (e.g. mlab1-sin1).
Within that tarball (tar -xzf <tarball_name>.tgz) are sets of files for each test run by that server:

*a .meta (metadata file)
*a cputime file (I currently have no idea what this is.)
*a .s2c_snaplog 
*a .c2s_snaplog 
*a .s2c_ndttrace (full server to client packet trace) *Optional*
*a .c2s_ndttrace(full client to server packet trace) *Optional*

####Meta file
The .meta file contains the following fields:
*Date/Time: 
*c2s_snaplog file: 
*c2s_ndttrace file: 
*s2c_snaplog file: 
*s2c_ndttrace file: 
*cputime file: 
*server IP address: 
*server hostname: mlab1.sin01.measurement-lab.org
*server kernel version: 
*client IP address: 
*client hostname: 
*client OS name: 
*client_browser name:
*client_application name: 
*Summary data: 
*Additional data:
*client.os.name: 
*client.browser.name: 
*client.kernel.version:
*client.version: 
*client.utorrent.version: 

####.s2c_snaplog/.c22_snaplog 
These file contain a header of the form: '2.5.27 201001301335 net100'
Followed by '/spec','/read', '/tune' field and then: ----Begin-Snap-Data----
I suggest 'head -n 500 filename.s2c_snaplog' if you want more details

####Cputime
A series of 0.1s timesteps followed by 4 int columns e.g.:
*0.00 0 0 0 0
*0.10 0 0 0 0
*etc
No idea what these signify currently
