class Fakes::AuthenticationService
  cattr_accessor :vacols_regional_offices, :ssoi_username, :ssoi_enabled

  def self.authenticate_vacols(regional_office, password)
    vacols_regional_offices[regional_office] == password
  end

  def self.ssoi_authentication_enabled?
    ssoi_enabled
  end
end
