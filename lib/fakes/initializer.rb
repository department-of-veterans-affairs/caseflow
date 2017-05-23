class Fakes::Initializer
  class << self
    def load!
      User.authentication_service = Fakes::AuthenticationService
      Appeal.repository = Fakes::AppealRepository
      Hearing.repository = Fakes::HearingRepository
    end

    def setup!
      development! if Rails.env.development? || Rails.env.demo?
    end

    private

    def development!
      load!

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

      Fakes::AppealRepository.seed!
      Fakes::HearingRepository.seed!
    end
  end
end
