# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :verify_access, only: [:index]

  def index
    render "admin/index" 
  end

  # Verifies user is admin and that feature toggle is enabled before showing admin page
  def verify_access
    return true if current_user.admin? && FeatureToggle.enabled?(:sys_admin_page, user: current_user)
    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def retrieve_veterans
    # Look for most recent completed System Admin Events with type of VETERAN_EXTRACT
    prev_event = SystemAdminEvent.where(
      event_type: "veteran_extract"
    )
    .where.not(
      completed_at: nil
    )
    .last

    last_completed_time = prev_event&.completed_at&.utc&.to_date || Time.at(0).utc.to_date
    results = VACOLS::Correspondent.extract(last_completed_time)
  end

  def extract_veterans_csv(input)
    # Create new event
    event = SystemAdminEvent.create(user: current_user, event_type: "veteran_extract")
    if input.empty?
      return true
    else
      formated_data = VACOLS::Correspondent.as_csv(input)
      filename = Time.zone.now.strftime("veteran-extract-%Y%m%d.csv")
      send_data formated_data, filename: filename, content_type: 'text/csv'
      event.update!(completed_at: Time.zone.now)
    end
  
    # error handling
    rescue StandardError => error
      render json: { error_code: error }, status: :internal_server_error
      event.update!(errored_at: Time.zone.now)
      return false
  end

  def veteran_extract 
    results = self.retrieve_veterans
    if (results.empty?)
      render json: { message: 'no veterans found'}
    else
      format.csv do
        self.extract_veterans_csv(results)
      end
    end
  end

end
