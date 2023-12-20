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

    last_completed_time = if FeatureToggle.enabled?(:vet_extract_timestamp, user: current_user)
                            prev_event&.completed_at&.utc&.to_date || Time.at(0).utc.to_date
                          else
                            Time.at(0).utc.to_date
                          end

    VACOLS::Correspondent.extract(last_completed_time)
  end

  def extract_veterans_csv(input)
    # Create new event
    event = SystemAdminEvent.create(user: current_user, event_type: "veteran_extract")
    if input.empty?
      render json: { message: "no veterans found", success: true }
    else
      formated_data = VACOLS::Correspondent.as_csv(input, col_sep)
      event.update!(completed_at: Time.zone.now)
      render json: { contents: formated_data, success: true }
    end

    # error handling
  rescue StandardError => error
    event.update!(errored_at: Time.zone.now)
    render json: { success: false, error: error }
  end

  def col_sep
    if FeatureToggle.enabled?(:vet_extract_pipe_delimited, user: current_user)
      "|"
    else
      ","
    end
  end

  def veteran_extract
    results = retrieve_veterans
    extract_veterans_csv(results)
  end
end
