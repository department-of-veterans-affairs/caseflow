class Fakes::AuthenticationService
  cattr_accessor :user_session
  cattr_accessor :vacols_regional_offices

  def self.default_user_session
    user_session
  end

  def self.get_user_session(user_id)
    user = User.find(user_id)
    roles = ["Certify Appeal", "Establish Claim"]
    # ANNE MERICA is a manager, everyone else doesn't
    # have that role.
    if user.css_id == "ANNE MERICA"
       roles.push("Manage Claim Establishment")
    end

    {
      "id" => user.css_id,
      "roles" => roles,
      "station_id" => user.station_id
    }
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
