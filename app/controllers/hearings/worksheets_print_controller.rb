# frozen_string_literal: true

class Hearings::WorksheetsPrintController < HearingsApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_access_to_reader_or_hearings

  def index
    stylesheets = {
      override_stylesheet: "print/hearings_worksheet_overrides",
      print_stylesheet: "print/hearings_worksheet"
    }

    render template: "hearings/index", locals: stylesheets
  end
end
