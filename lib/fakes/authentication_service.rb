class Fakes::AuthenticationService
  cattr_accessor :vacols_regional_offices

  def self.authenticate_vacols(regional_office, password)
    vacols_regional_offices[regional_office] == password
  end
end
