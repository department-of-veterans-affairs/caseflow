CONNECT sys/Oradoc_db1@//localhost:1521/BVAP as SYSDBA;

ALTER SESSION set "_ORACLE_SCRIPT"=true;

CREATE USER VACOLS_DEV IDENTIFIED BY VACOLS_DEV;
GRANT UNLIMITED TABLESPACE TO VACOLS_DEV;
GRANT CREATE SESSION TO VACOLS_DEV;

CREATE USER VACOLS_TEST IDENTIFIED BY VACOLS_TEST;
GRANT UNLIMITED TABLESPACE TO VACOLS_TEST;
GRANT CREATE SESSION TO VACOLS_TEST;

ALTER PROFILE DEFAULT LIMIT PASSWORD_REUSE_TIME unlimited;
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME unlimited;

@/ORCL/vacols_copy_1_tablespaces.sql
@/ORCL/vacols_copy_2_tables_dev.sql
@/ORCL/vacols_copy_2_tables_test.sql
@/ORCL/vacols_copy_3_indexes_dev.sql
@/ORCL/vacols_copy_3_indexes_test.sql
@/ORCL/vacols_copy_7_sequences_dev.sql
@/ORCL/vacols_copy_7_sequences_test.sql
@/ORCL/vacols_copy_4_triggers_dev.sql
@/ORCL/vacols_copy_4_triggers_test.sql
@/ORCL/vacols_copy_5_functions_dev.sql
@/ORCL/vacols_copy_5_functions_test.sql
@/ORCL/vacols_copy_6_procedures_dev.sql
@/ORCL/vacols_copy_6_procedures_test.sql

dbms_space_admin.tablespace_rebuild_bitmaps;

alter database datafile '/opt/oracle/oradata/BVAP/system01.dbf' resize 1000m;
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
alter database datafile '/opt/oracle/oradata/BVAP/sysaux01.dbf' resize 500m;
alter database datafile '/opt/oracle/oradata/BVAP/users01.dbf' resize 34m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_corres01.dbf' resize 49m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_ndx.dbf' resize 529m;
alter database datafile '/opt/oracle/oradata/BVAP/employee.dbf' resize 18m;
alter database datafile '/opt/oracle/oradata/BVAP/photo.dbf' resize 33m;
alter database datafile '/opt/oracle/oradata/BVAP/vcl_othdocs_ndx.dbf' resize 33m;

exec DBMS_XDB_CONFIG.sethttpsport(0);
alter system set dispatchers='';

exit
