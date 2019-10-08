# frozen_string_literal: true

class Hearings::HearingDayPrintController < HearingsApplicationController
  include HearingsConcerns::VerifyAccess

  before_action :verify_view_hearing_schedule_access, only: [:index]
  skip_before_action :deny_vso_access, only: [:index]

  def index
    render "hearings/index", locals: { print_stylesheet: "print/hearings_schedule" }
  end
end
