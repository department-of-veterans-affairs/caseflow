class Fakes::Initializer
  def self.development!
    User.authentication_service = Fakes::AuthenticationService
    User.authentication_service.vacols_regional_offices = {
      "DSUSER" => "DSUSER",
      "RO13" => "RO13"
    }

    Appeal.repository = Fakes::AppealRepository
    Fakes::AppealRepository.seed!
  end
end
