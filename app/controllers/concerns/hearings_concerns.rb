# frozen_string_literal: true

module HearingsConcerns
  module VerifyAccess
    extend ActiveSupport::Concern

    def verify_access_to_reader_or_hearings
      verify_authorized_roles("Reader", "Hearing Prep", "Edit HearSched", "Build HearSched")
    end

    def verify_access_to_hearings_details
      verify_authorized_roles("Reader", "Hearing Prep", "Edit HearSched", "Build HearSched", "VSO")
    end

    def verify_edit_worksheet_access
      verify_authorized_roles("Hearing Prep")
    end

    def verify_access_to_hearings
      verify_authorized_roles("Hearing Prep", "Edit HearSched", "Build HearSched", "RO ViewHearSched")
    end

    def verify_access_to_hearings_update
      verify_authorized_roles("Hearing Prep", "Edit HearSched", "Build HearSched", "RO ViewHearSched", "VSO")
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

    # Only allow for VSOs to access hearings they are representing
    def check_vso_representation
      if current_user.vso_employee?
        # Account for the different params given by different controllers
        hearing_id = (params[:action] == "show_hearing_details_index") ? params[:hearing_id] : params[:id]

        unless Hearing.find_hearing_by_uuid_or_vacols_id(hearing_id)&.assigned_to_vso?(current_user)
          session["return_to"] = request.original_url
          redirect_to "/unauthorized"
        end
      end
    end

    def verify_transcription_user
      if !TranscriptionTeam.singleton.user_has_access?(current_user)
        redirect_to "/unauthorized"
      end
    end
  end
end
