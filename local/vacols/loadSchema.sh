for i in {1..240}
do
  if ! bash -c "source /home/oracle/.bashrc; sqlplus /nolog @/ORCL/setup_vacols.sql" | grep "Not connected" ;
  then
    echo "Schema loaded."
    break
  fi
  sleep 1
done
