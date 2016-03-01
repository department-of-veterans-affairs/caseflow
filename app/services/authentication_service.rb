class AuthenticationService
  def self.authenticate_vacols(regional_office, password)
    db = Rails.application.config.database_configuration[Rails.env]

    begin
      oci = OCI8.new(regional_office, password, "#{db['host']}:#{db['port']}/#{db['database']}")
    rescue OCIError
      return false
    end

    oci.logoff
    true
  end

  def self.ssoi_authentication_enabled?
    false
  end

  def self.ssoi_username
    "TESTMODE"
  end
end
