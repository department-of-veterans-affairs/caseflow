# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :verify_access, only: [:index]

  def index
    respond_to do |format|
      format.html { render "admin/index" }
      format.csv do
        self.veteran_extract
      end
    end
  end

  # Verifies user is admin and that feature toggle is enabled before showing admin page
  def verify_access
    return true if current_user.admin? && FeatureToggle.enabled?(:sys_admin_page, user: current_user)
    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def veteran_extract
    results = VACOLS::Correspondent.extract
    if results.empty?
      return true
    else
      formated_data = VACOLS::Correspondent.as_csv(results)
      filename = Time.zone.now.strftime("veteran-extract-%Y%m%d.csv")
      send_data formated_data, filename: filename, content_type: 'text/csv'
    end
    

    # error handling
  rescue StandardError => error
    render json: { error_code: error_id }, status: :internal_server_error
    return false
  end
end
