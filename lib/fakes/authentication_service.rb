# frozen_string_literal: true

class Fakes::AuthenticationService
  cattr_accessor :user_session
  cattr_accessor :vacols_regional_offices

  def self.default_user_session
    user_session
  end

  def self.get_user_session(user_id)
    user = User.find(user_id)

    if user.roles.include?("System Admin")
      Functions.grant!("System Admin", users: [user.css_id])
    end

    {
      "id" => user.css_id,
      "css_id" => user.css_id,
      "roles" => user.roles,
      "station_id" => user.station_id,
      "name" => user.full_name,
      "email" => user.email,
      "timezone" => user.timezone
    }
  end

  def self.find_ro(regional_office)
    # case-insensitive compare on all the keys
    vacols_regional_offices.keys.find do |known_ro|
      known_ro.casecmp(regional_office) == 0
    end
  end
end
