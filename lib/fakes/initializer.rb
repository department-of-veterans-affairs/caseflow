# frozen_string_literal: true

class Fakes::Initializer
  class << self
    def load!
      User.authentication_service = Fakes::AuthenticationService
      CAVCDecision.repository = Fakes::CAVCDecisionRepository
    end

    # This method is called only 1 time during application bootup
    def app_init!(rails_env)
      if rails_env.ssh_forwarding? && !running_rake_command?
        User.authentication_service = Fakes::AuthenticationService
        # This sets up the Fake::VBMSService with documents for the VBMS ID DEMO123. We normally
        # set this up in Fakes::AppealRepository.seed! which we don't call for this environment.
        Fakes::VBMSService.document_records = { "DEMO123" => Fakes::Data::AppealData.static_reader_documents }
      end

      if rails_env.demo? || rails_env.development?
        # If we are running a rake command like `rake db:seed` or
        # `rake db:schema:load`, we do not want to try and seed the fakes
        # because our schema may not be loaded yet and it will fail!
        if running_rake_command?
          load!
        else
          load_fakes_and_seed!(rails_env: rails_env)
        end
      end
    end

    # This setup method is called on every request during development
    # to properly reload class attributes like the fake repositories and
    # their seed data (which is currently cached as class attributes)
    def setup!(rails_env)
      load_fakes_and_seed!(rails_env: rails_env) if rails_env.development?
    end

    private

    def load_fakes_and_seed!(rails_env:)
      load!

      User.authentication_service.vacols_regional_offices = { "DSUSER" => "DSUSER", "RO13" => "RO13" }

      User.authentication_service.user_session = {
        "id" => "Fake User", "css_id" => "FAKEUSER",
        "roles" =>
          ["Certify Appeal", "Establish Claim", "Download eFolder", "Manage Claim Establishment"],
        "station_id" => "283",
        "email" => "america@example.com",
        "name" => "Cave Johnson"
      }

      # FACOLS needs to match veteran records through Fakes::BGSService for Dispatch(EPs)
      if rails_env.development?
        Fakes::BGSService.create_veteran_records
      end
    end

    def running_rake_command?
      File.basename($PROGRAM_NAME) == "rake"
    end
  end
end
