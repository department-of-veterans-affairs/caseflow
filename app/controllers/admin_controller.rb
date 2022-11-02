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
      respond_to do |format|
        format.csv do
          response.headers['Content-Type'] = 'text/csv'
          send_data VACOLS::Correspondent.to_csv(results), filename: Date.today.to_s
        end
      end

      # return results
    end
    

    # error handling
    # return false
  end
end
