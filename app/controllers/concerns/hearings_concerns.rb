# frozen_string_literal: true

module HearingsConcerns
  module VerifyAccess
    extend ActiveSupport::Concern

    included do
      before_action :verify_access, except: [:show_print, :show, :update, :find_closest_hearing_locations]
      before_action :verify_access_to_reader_or_hearings, only: [:show_print, :show]
      before_action :verify_access_to_hearing_prep_or_schedule, only: [:update]
    end

    def verify_access
      verify_authorized_roles("Hearing Prep")
    end

    def verify_access_to_reader_or_hearings
      verify_authorized_roles("Reader", "Hearing Prep", "Edit HearSched", "Build HearSched")
    end

    def verify_access_to_hearing_prep_or_schedule
      verify_authorized_roles("Hearing Prep", "Edit HearSched", "Build HearSched", "RO ViewHearSched")
    end
  end
end
