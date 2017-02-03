
# VACOLS throttles the rate of new connections, create up front to prevent 
# blocking as pool grows under load
ActiveSupport.on_load(:active_record_vacols) do
  db_config =  Rails.application.config.database_configuration[Rails.env]

  # use specified initial pool size, default to half the maximum size
  initial_pool_size = (ENV['DB_CONN_POOL_INITIAL_SIZE'] || db_config['pool'] / 2).to_i
  threads = []
  pool = VACOLS::Record.connection_pool

  initial_pool_size.times do |i|
    threads << Thread.new do
      conn = pool.connection
      conn.close
    end
  end

  threads.each(&:join)
end
