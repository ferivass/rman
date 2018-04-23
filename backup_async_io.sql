set line 1000
set pagesize 2000
set trimspool on
set colsep ';'

col FILENAME format a60

/*
Use V$BACKUP_SYNC_IO and V$BACKUP_ASYNC_IO to determine the source of backup or restore bottlenecks and to determine 
the progress of backup jobs. 
- V$BACKUP_SYNC_IO contains rows when the I/O is synchronous to the process 
(or thread, on some platforms) performing the backup.
- V$BACKUP_ASYNC_IO contains rows when the I/O is asynchronous. 
Asynchronous I/O is obtained either with I/O processes or because it is 
supported by the underlying operating system.
*/

SPOOL backup_async_io.output

SELECT device_type "Device",
       TYPE,
       filename,
       to_char(open_time, 'mm/dd/yyyy hh24:mi:ss') OPEN,
       to_char(close_time, 'mm/dd/yyyy hh24:mi:ss') CLOSE,
       elapsed_time et,
       effective_bytes_per_second eps,
       io_count,
       ready,
       short_waits,
       long_waits,
       --long_waits / io_count,
       filename
FROM   v$backup_async_io
WHERE  close_time > SYSDATE - 4
ORDER  BY close_time DESC;

-- To determine whether there is an I/O problem, we can look at the ratio of  I/Os to long  waits (LONG_WAITS/IO_COUNTS)

SELECT io_count,
       ready,
       short_waits,
       long_waits,
       io_count,
       --long_waits / io_count,
       filename
FROM   v$backup_async_io
where TYPE in ('INPUT','OUTPUT');

spool off

/*
The numbers returned by this indicate some sort of I/O bottleneck is causing grief (in this case is a single CPU machine).
Explanation :LONG_WAITS : The number of times that a buffer was not immediately available, and only became available after a blocking wait was issued.
In the above many files had to wait 30%-66% of the amount of IO's for a LONG-WAIT. This indicate a OS-bufercache / configuration / disk problem.
*/


exit
