CONNECT sys/Oradoc_db1@//localhost:1521/BVAP as SYSDBA;

ALTER SESSION set "_ORACLE_SCRIPT"=true;

CREATE USER VACOLS IDENTIFIED BY VACOLS;
GRANT UNLIMITED TABLESPACE TO VACOLS;
GRANT CREATE SESSION TO VACOLS;

@/ORCL/vacols_copy_1_tablespaces.sql
@/ORCL/vacols_copy_2_tables.sql
@/ORCL/vacols_copy_3_indexes.sql
@/ORCL/vacols_copy_7_sequences.sql
@/ORCL/vacols_copy_4_triggers.sql
@/ORCL/vacols_copy_5_functions.sql
@/ORCL/vacols_copy_6_procedures.sql

alter database datafile '/opt/oracle/oradata/BVAP/system01.dbf' resize 798m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_attach_ndx.dbf' resize 401m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_brieff.dbf' resize 17m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_death.dbf' resize 17m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_folder_ndx.dbf' resize 263m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_rmdrea.dbf' resize 33m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_corres_ndx1.dbf' resize 300m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_tinum_ndx.dbf' resize 65m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_assign_ndx.dbf' resize 985m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_brieff_ndx.dbf' resize 453m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_death_ndx.dbf' resize 33m;
alter database datafile '/opt/oracle/oradata/BVAP/undotbs01.dbf' resize 77m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_bfcorlid_ndx.dbf' resize 89m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_decass.dbf' resize 65m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_mail.dbf' resize 177m;
alter database datafile '/opt/oracle/oradata/BVAP/decrev.dbf' resize 33m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_attytime.dbf' resize 199m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_hearsched.dbf' resize 79m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_issues.dbf' resize 97m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_folder01.dbf' resize 17m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_priorlc_ndx.dbf' resize 649m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_titrnum_ndx.dbf' resize 89m;
alter database datafile '/opt/oracle/oradata/BVAP/sysaux01.dbf' resize 440m;
alter database datafile '/opt/oracle/oradata/BVAP/users01.dbf' resize 34m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_corres01.dbf' resize 49m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_ndx.dbf' resize 529m;
alter database datafile '/opt/oracle/oradata/BVAP/employee.dbf' resize 18m;
alter database datafile '/opt/oracle/oradata/BVAP/photo.dbf' resize 33m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_othdocs_ndx.dbf' resize 33m;

exec DBMS_XDB_CONFIG.sethttpsport(0);
alter system set dispatchers='';

exit
