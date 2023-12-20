# frozen_string_literal: true

class Hearings::WorksheetsPrintController < HearingsApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_access_to_reader_or_hearings, only: [:index]

  # Skips the action defined in the parent.
  skip_before_action :verify_view_hearing_schedule_access, only: [:index]

  def index
    stylesheets = {
      override_stylesheet: "print/hearings_worksheet_overrides",
      print_stylesheet: "print/hearings_worksheet"
    }

    render template: "hearings/index", locals: stylesheets
  end
end
