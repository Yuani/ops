#!/usr/bin/env python
import commands,time,json

db_host='127.0.0.1'
db_port='3306'
db_user='monitor'
db_passwd='pwd'
mysqlAdmin='/data/softwares/mysql-percona/bin/mysqladmin'
mysql='/data/softwares/mysql-percona/bin/mysql'
db_auth=' -h %s -P %s -u %s -p%s ' % (db_host,db_port,db_user,db_passwd)

# extended-status
metric={
'Com_update':0,
'Com_insert':0,
'Com_select':0,
'Com_delete':0,
'Com_commit':0,
'Questions':0,
'Com_rollback':0,
'Open_files':0,
'Open_tables':0,
'Threads_connected':0,
'Threads_running':0,
'Bytes_sent':0,
'Bytes_received':0,
'subordinate':1,
'alive':0,
}



def get_endpoint():
    cfg='/data/softwares/openfalcon/falcon-agent/cfg.json'
    endpoint='127.0.0.1'
    with open(cfg) as f:
        data=json.load(f)
        endpoint=data['hostname']
    return endpoint


def get_mysqladmin_extended_status():
	data=[]
	endpoint=get_endpoint()
	ts=time.time()
	step=60
	cmd='%s %s  extended-status' % (mysqlAdmin, db_auth)
#	print cmd
	status=commands.getoutput(cmd)
	for line in status.split('\n'):
		if '|' not in line:continue
		if line.split('|')[1].strip() in metric.keys():
			m = line.split('|')[1].strip()
			value = line.split('|')[2].strip()
			print m,value
			data.append({'endpoint':endpoint,'timstamp':long(ts),'step': step,'metric':'mysql.'+m,'value':long(value),'tags':"",'counterType':'COUNTER'})
	cmd='%s %s stat' % (mysqlAdmin, db_auth)
	stat=commands.getoutput(cmd).split('\n')[1].split()
	data.append({'endpoint':endpoint,'timstamp':long(ts),'step': step,'metric':'mysql.Uptime','value':long(stat[1]),'tags':"",'counterType':'GAUGE'})
	data.append({'endpoint':endpoint,'timstamp':long(ts),'step': step,'metric':'mysql.Threads','value':long(stat[3]),'tags':"",'counterType':'GAUGE'})

	#ping
	cmd='%s %s ping' % (mysqlAdmin, db_auth)
	ping=commands.getoutput(cmd).split('\n')[1]
	if 'alive' in ping: metric['alive']=1
	data.append({'endpoint':endpoint,'timstamp':long(ts),'step': step,'metric':'mysql.alive','value':long(metric['alive']),'tags':"",'counterType':'GAUGE'})

	### subordinate status monitor
	#subordinateMetric=['Subordinate_IO_Running','Subordinate_SQL_Running','Seconds_Behind_Main']
	#cmd='%s %s -e  "show subordinate status\G"' % (mysql, db_auth)
	#sstat=commands.getoutput(cmd).split('\n')[1:]
	#if sstat[11].split(':')[1].strip() == 'No' or sstat[12].split(':')[1].strip() == 'No':
	#	metric['subordinate']=0
	#data.append({'endpoint':endpoint,'timstamp':long(ts),'step': step,'metric':'mysql.subordinate','value':long(metric['subordinate']),'tags':"",'counterType':'GAUGE'})
	#data.append({'endpoint':endpoint,'timstamp':long(ts),'step': step,'metric':'mysql.behind','value':long(sstat[33].split(':')[1].strip()),'tags':"",'counterType':'GAUGE'})

	print json.dumps(data,indent=4)

if __name__ == '__main__':
	get_mysqladmin_extended_status()

