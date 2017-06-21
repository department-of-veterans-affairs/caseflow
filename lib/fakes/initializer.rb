class Fakes::Initializer
  class << self
    def load!
      PowerOfAttorney.repository = Fakes::PowerOfAttorneyRepository
      User.authentication_service = Fakes::AuthenticationService
      Hearing.repository = Fakes::HearingRepository
      Appeal.repository = Fakes::AppealRepository
      CAVCDecision.repository = Fakes::CAVCDecisionRepository
      User.case_assignment_repository = Fakes::CaseAssignmentRepository
    end

    # This method is called only 1 time during application bootup
    def app_init!(rails_env)
      load_fakes_and_seed! if rails_env.development? || rails_env.demo?
    end

    # This setup method is called on every request during development
    # to properly reload class attributes like the fake repositories and
    # their seed data (which is currently cached as class attributes)
    def setup!(rails_env, app_name: nil)
      load_fakes_and_seed!(app_name: app_name) if rails_env.development? || rails_env.test?
    end

    private

    def load_fakes_and_seed!(app_name: nil)
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

      Fakes::AppealRepository.seed!(app_name: app_name)
      Fakes::HearingRepository.seed! if app_name.nil? || app_name == "hearings"
    end
  end
end
