##################### THIS SCRIPT IS TO PERFORM CM JOB FAILURE ###########################
# # Modification History
# ====================
# Who                 Ver.  When      What
# ===                 ====  ====      ====
# Indraneil Seal      1.0   07-May-21  Creation
#
#######################################################################################################################

dt=$(date +%Y.%m.%d-%H.%M.%S)
INSTANCE=$1
HOST_NAME=`hostname | cut -d'.' -f1`
APPSLOGIN=apps/<apps_pwd>
SCRIPT_LOC=/home/applmgr/home/HC_scripts
LOG=/home/applmgr/home/HC_scripts/cm_job_failure_mail_`date +\%d\%b\%y`.html

echo "<h3 ALIGN=CENTER > FAILED CONCURRENT JOBS IN LAST 3 HRS </h3>" >>$LOG

############################################# CHECK FAILED CONCURRENT JOBS IN LAST 3 YEARS  ################################################################
. $APPL_TOP/APPS${INSTANCE}_$HOST_NAME.env

get_count=`sqlplus -S $APPSLOGIN@$INSTANCE << EOF
set heading off
set feedback off
select count(*) from
(select a.request_id
,b.USER_CONCURRENT_PROGRAM_NAME "PROGRAM_NAME"
,c.user_name
,outfile_node_name
,to_char(a.actual_completion_date,'MM-DD-YY HH24:MI') "COMPLETION_DATE"
,status_code
 ,completion_text
from fnd_concurrent_requests  a ,apps.fnd_concurrent_programs_vl b
,fnd_user c
where
a.CONCURRENT_PROGRAM_ID=b.CONCURRENT_PROGRAM_ID
and a.requested_by=c.user_id
and a.PROGRAM_APPLICATION_ID=b.APPLICATION_ID
and phase_code='C'
and status_code in ('E','Q','X')
and actual_completion_date  > trunc(sysdate -3/24,'HH24')
and actual_completion_date < trunc(sysdate,'HH24')
order by a.actual_completion_date desc);
EOF`

if [ $get_count -gt 0 ];then
sqlplus -S -M "HTML ON TABLE 'BORDER="2"'" $APPSLOGIN@$INSTANCE << EOF  >>$LOG
select a.request_id
,b.USER_CONCURRENT_PROGRAM_NAME "PROGRAM_NAME"
,c.user_name
,logfile_node_name
,outfile_node_name
,to_char(a.actual_completion_date,'MM-DD-YY HH24:MI') "COMPLETION_DATE"
,phase_code
,status_code
 ,completion_text
from fnd_concurrent_requests  a ,apps.fnd_concurrent_programs_vl b
,fnd_user c
where
a.CONCURRENT_PROGRAM_ID=b.CONCURRENT_PROGRAM_ID
and a.requested_by=c.user_id
and a.PROGRAM_APPLICATION_ID=b.APPLICATION_ID
and phase_code='C'
and status_code in ('E','Q','X')
and actual_completion_date  > trunc(sysdate -3/24,'HH24')
and actual_completion_date < trunc(sysdate,'HH24')
order by a.actual_completion_date desc;
exit;
EOF
export MAILTO="email1@domain email2@domain"
export CONTENT="/home/applmgr/home/HC_scripts/cm_job_failure_mail_`date +\%d\%b\%y`.html"
export SUBJECT="EBS FAILED CM JOBS REPORT ON `date`  "
(
 echo "Subject: $SUBJECT"
 echo "MIME-Version: 1.0"
 echo "Content-Type: text/html"
 echo "Content-Disposition: inline"
 echo "To: $MAILTO"
 cat $CONTENT
) | /usr/sbin/sendmail -t $MAILTO
else
    echo "No CM Jobs failed in last 3 hrs!!" >> $LOG
fi

mv $LOG /home/applmgr/home/HC_scripts/archive_reports/cm_job_failure_mail_${dt}.html
