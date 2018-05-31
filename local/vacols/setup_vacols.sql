CONNECT sys/Oradoc_db1@BVAP as sysdba

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
exit
