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

  def veteran_extract
    results = VACOLS::Correspondent.extract
    if results.empty?
      return true
    else
      formated_data = VACOLS::Correspondent.as_csv(results)
      respond_to do |format|
        byebug
        format.html
        format.csv do
          send_data formated_data, filename: Date.today.to_s, content_type: 'text/csv'
        end
      end
    end
    

    # error handling
    # return false
  end
end
