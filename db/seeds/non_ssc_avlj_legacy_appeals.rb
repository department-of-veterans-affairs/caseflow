# frozen_string_literal: true

module Seeds
  class NonSscAvljLegacyAppeals < Base
    def initialize
      initialize_np_legacy_appeals_file_number_and_participant_id
      initialize_priority_legacy_appeals_file_number_and_participant_id
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      create_avljs
      create_legacy_appeals
    end

    private

    def initialize_np_legacy_appeals_file_number_and_participant_id
    end

    def initialize_priority_legacy_appeals_file_number_and_participant_id
    end

    def create_avljs
    end

    def create_legacy_appeals
    end

    def create_non_ssc_avlj
    end

    def create_ssc_avlj
    end

    def create_non_priority_legacy_appeal
    end

    def create_priority_legacy_appeal
    end

    def assign_last_hearing_to_avlj
    end

    def sign_most_recent_decision_of_legacy_appeal(avlj)
    end

    def set_docket_date
      #BRIEFF.BFD19
    end

    def create_second_hearing_for_legacy_appeal(legacy_appeal)
    end

  end
end
