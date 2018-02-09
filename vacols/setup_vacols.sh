echo "Setting up VACOLS schema"
docker exec --tty -i VACOLS_DB bash -c "source /home/oracle/.bashrc; sqlplus sys/Oradoc_db1 as SYSDBA @/ORCL/setup_vacols.sql; exit"
