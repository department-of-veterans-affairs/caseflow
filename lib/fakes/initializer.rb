class Fakes::Initializer
  def self.development!
    User.authentication_service = Fakes::AuthenticationService
    User.authentication_service.vacols_regional_offices = {
      "DSUSER" => "DSUSER",
      "RO13" => "RO13"
    }

    User.authentication_service.user_session = {
      "id" => "Fake User",
      "roles" => ["Certify Appeal", "Establish Claim", "Manage Claim Establishment"],
      "station_id" => "283",
      "email" => "america@example.com",
      "name" => "Cave Johnson"
    }

    Appeal.repository = Fakes::AppealRepository
    Fakes::AppealRepository.seed!
  end
end
