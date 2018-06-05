class Hearings::ScheduleController < HearingsController
  before_action :verify_access

  # Work in progress. More endpoints to be implemented soon.

  def index
    render "out_of_service", layout: "application"
  end

  private

  def verify_access
    verify_authorized_roles("Hearing Schedule")
  end
end