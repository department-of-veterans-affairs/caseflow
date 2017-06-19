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
      if rails_env.development? || rails_env.demo?

        # If we are booting up the rails console or server we want to load
        # the fakes & seed our in-memory VACOLS "DB"
        #
        # When running other rake commands (e.g. `rake db:seed`), we do **NOT**
        # want to seed the fakes because
        #   1) it's unnecessary and slows down the command
        #   2) it can cause the seed data we put into postgres vacols_ids to become
        #      unaligned with what we put into our in-memory VACOLS "DB"
        if Rails.const_defined?("Console") || Rails.const_defined?("Server")
          load_fakes_and_seed!
        else
          load!
        end
      end
    end

    # This setup method is called on every request during development
    # to properly reload class attributes like the fake repositories and
    # their seed data (which is currently cached as class attributes)
    def setup!(rails_env, app_name: nil)
      load_fakes_and_seed!(app_name: app_name) if rails_env.development?
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
