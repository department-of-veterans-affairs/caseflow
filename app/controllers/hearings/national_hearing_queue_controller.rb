# frozen_string_literal: true

class Hearings::NationalHearingQueueController < ApplicationController
  include GenericTaskPaginationConcern

  def index
    respond_to do |format|
      format.html { render "national_hearing_queue/index" }
      format.json { queue_entries }
    end
  end

  def cutoff_date
    # Date will come from a table that hasn't been created yet

    # user_can_edit will be true/false depending on if the current_user
    #  is in the group of approved cutoff date updaters.
    render json: { cutoff_date: Date.new(2019, 12, 31), user_can_edit: true }
  end

  def update_cutoff_date
    # Permissions check first - in a before_action, probably.

    permitted_params = params.permit(:cutoff_date)

    unless permitted_params["cutoff_date"]
      # Validate validity of date
      #  - Must be an actual date
      #  - Must be today or in the past
      # Return an error if these conditions are met (not currently implemented)

      Rails.logger.info("Updating the cutoff date to #{permitted_params['cutoff_date']}")

      return render status: :ok
    end

    render json: { error: "A cutoff date was not provided" },
           status: :bad_request,
           content_type: "application/json"
  end

  private

  def allowed_params
    params.permit(
      :tab,
      :search_query,
      { filter: [] },
      :page
    )
  end

  def queue_entries
    tab_name = allowed_params[Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM.to_sym]

    entries = NationalHearingQueueEntry.all.order(:priority_queue_number)

    filtered_entries = case tab_name
                       when "all"
                         entries
                       when "unassigned"
                         entries.where(assigned_to_type: "Organization", task_status: "assigned")
                       when "on_hold"
                         entries.where(task_status: "on_hold")
                       when "assigned"
                         entries.where(assigned_to_type: "User", task_status: "assigned")
                       else
                         return render json: { error: "#{tab_name} is not a recognized tab name." }
                       end

    render json: pagination_json(filtered_entries)
  end
end
