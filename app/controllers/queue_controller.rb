# frozen_string_literal: true

require "pdfkit"

class QueueController < ApplicationController
  before_action :react_routed, :check_queue_out_of_service, :verify_access
  skip_before_action :deny_vso_access

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    render "queue/index"
  end

  def check_queue_out_of_service
    render "out_of_service", layout: "application" if Rails.cache.read("queue_out_of_service")
  end

  def verify_access
    restricted_roles = ["Case Details"]
    current_user_has_restricted_role = !(restricted_roles & current_user.roles).empty?
    if current_user_has_restricted_role && request.env["PATH_INFO"] == "/queue"
      Rails.logger.info("redirecting user with Case Details role from queue to search")
      session["return_to"] = request.original_url
      redirect_to "/search"
    end
    nil
  end
end
