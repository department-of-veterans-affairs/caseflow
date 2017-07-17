class HealthCheck
  def healthy?
    vacols_db_connection_active?
  end

  def vacols_db_connection_active?
    Appeal.repository.vacols_db_connection_active?
  end
end
