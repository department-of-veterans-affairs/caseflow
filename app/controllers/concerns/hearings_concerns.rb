# frozen_string_literal: true

module HearingsConcerns
  module VerifyAccess
    extend ActiveSupport::Concern

    def verify_access_to_reader_or_hearings
      verify_authorized_roles("Reader", "Hearing Prep", "Edit HearSched", "Build HearSched")
    end

    def verify_edit_worksheet_access
      verify_authorized_roles("Hearing Prep")
    end

    def verify_access_to_hearings
      verify_authorized_roles("Hearing Prep", "Edit HearSched", "Build HearSched", "RO ViewHearSched")
    end

    def verify_build_hearing_schedule_access
      verify_authorized_roles("Build HearSched")
    end

    def verify_edit_hearing_schedule_access
      verify_authorized_roles("Edit HearSched", "Build HearSched")
    end

    def verify_view_hearing_schedule_access
      verify_authorized_roles("Edit HearSched", "Build HearSched", "RO ViewHearSched", "VSO", "Hearing Prep")
    end
  end
end
