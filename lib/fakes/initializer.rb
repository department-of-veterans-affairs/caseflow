class Fakes::Initializer
  class << self
    def load!
      PowerOfAttorney.repository = Fakes::PowerOfAttorneyRepository
      User.authentication_service = Fakes::AuthenticationService
      Hearing.repository = Fakes::HearingRepository
      HearingDocket.repository = Fakes::HearingRepository
      Appeal.repository = Fakes::AppealRepository
      CAVCDecision.repository = Fakes::CAVCDecisionRepository
      User.appeal_repository = Fakes::AppealRepository
    end

    # This method is called only 1 time during application bootup
    def app_init!(rails_env)
      if rails_env.development? || rails_env.demo?
        # If we are running a rake command like `rake db:seed` or
        # `rake db:schema:load`, we do not want to try and seed the fakes
        # because our schema may not be loaded yet and it will fail!
        if running_rake_command?
          load!
        else
          load_fakes_and_seed!
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
        "roles" => ["Certify Appeal", "Establish Claim", "Manage Claim Establishment", "Hearing Prep"],
        "station_id" => "283",
        "email" => "america@example.com",
        "name" => "Cave Johnson"
      }

      Fakes::AppealRepository.seed!(app_name: app_name)
      Fakes::HearingRepository.seed! if app_name.nil? || app_name == "hearings"

      load_ramp_election_veteran_fakes
    end

    def load_ramp_election_veteran_fakes
      9.times do |i|
        Generators::Veteran.build(file_number: "#{i}5555555")
        Generators::Veteran.build(file_number: "#{i}0555555")
      end
    end

    def running_rake_command?
      File.basename($PROGRAM_NAME) == "rake"
    end
  end
end
