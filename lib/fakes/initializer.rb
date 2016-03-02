class Fakes::Initializer
  def self.development!
    User.authentication_service = Fakes::AuthenticationService
    User.authentication_service.vacols_regional_offices = { "DSUSER" => "DSUSER" }
    User.authentication_service.ssoi_enabled = false
    User.authentication_service.ssoi_username = "STUB"

    Appeal.repository = Fakes::AppealRepository
    Fakes::AppealRepository.seed!
  end
end
