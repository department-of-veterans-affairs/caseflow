# frozen_string_literal: true

class AdminController < ApplicationController
  skip_before_action :verify_authentication, only: [
    :show,
    # :verify_access,
    :index
  ]

  def show
    no_cache
    respond_to do |format|
      format.html { render template: "admin/index" }
    end
  end

  def index
    render "admin/index"
  end

  # def verify_access
  #   restricted_roles = ["Case Details"]
  #   current_user_has_restricted_role = !(restricted_roles & current_user.roles).empty?
  #   if current_user_has_restricted_role && request.env["PATH_INFO"] == "/queue"
  #     Rails.logger.info("redirecting user with Case Details role from queue to search")
  #     session["return_to"] = request.original_url
  #     redirect_to "/search"
  #   end
  #   nil
  # end
end
