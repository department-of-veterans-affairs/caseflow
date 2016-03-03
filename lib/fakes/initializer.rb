class Fakes::Initializer
  def self.development!
    User.authentication_service = Fakes::AuthenticationService
    User.authentication_service.vacols_regional_offices = { "DSUSER" => "DSUSER" }

    Appeal.repository = Fakes::AppealRepository
    Fakes::AppealRepository.seed!
  end
end
