CREATE USER VACOLS IDENTIFIED BY VACOLS;
GRANT UNLIMITED TABLESPACE TO VACOLS;
GRANT CREATE SESSION TO VACOLS;

@vacols_copy_1_tablespaces.sql
@vacols_copy_2_tables.sql
@vacols_copy_5_functions.sql
@vacols_copy_6_procedures.sql
exit
