class Fakes::AuthenticationService
  cattr_accessor :user_session
  cattr_accessor :vacols_regional_offices

  def self.default_user_session
    user_session
  end

  def self.authenticate_vacols(regional_office, password)
    normalized_ro = find_ro(regional_office)
    actual_password = vacols_regional_offices[normalized_ro]
    actual_password == password
  end

  def self.find_ro(regional_office)
    # case-insensitive compare on all the keys
    vacols_regional_offices.keys.find do |known_ro|
      known_ro.casecmp(regional_office) == 0
    end
  end
end
