# frozen_string_literal: true

class QueueController < ApplicationController
  before_action :react_routed, :check_queue_out_of_service, :verify_access
  skip_before_action :deny_vso_access

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def index
    puts "---------------------------------- queue index -----------------------------------"
    start_time1 = Time.zone.now
    render_block = nil
    StackProf.run(mode: :wall, out: "queue_index.dump") do
      # primed_tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
      # primed_tasks = AppealRepository.eager_load_legacy_appeals_for_tasks_in_queue(tasks, testing_appeal_includes)
      render_block = render("queue/index")
    end
    end_time1 = Time.zone.now
    puts "Queue index render took: #{(end_time1 - start_time1) * 1000}"
    # render "queue/index"
    # byebug
    render_block
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
