# frozen_string_literal: true

class Hearings::NationalHearingQueueController < ApplicationController
  include GenericTaskPaginationConcern

  # We don't need this
  SORT_COLUMN_MAPPINGS = {}.freeze

  def index
    respond_to do |format|
      format.html { render "national_hearing_queue/index" }
      format.json { queue_entries }
    end
  end

  private

  def allowed_params
    params.permit(
      :task_id,
      :tab,
      :sort_by,
      :order,
      :search_query,
      { filter: [] },
      :page,
      :all
    )
  end

  def queue_entries
    tab_name = allowed_params[Constants.QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM.to_sym]

    entries = NationalHearingQueueEntry.all.order(:priority_queue_number)

    filtered_entries = case tab_name
                       when "all" then entries
                       when "unassigned" then entries.where(assigned_to_type: "Organization", task_status: "assigned")
                       when "on_hold" then entries.where(task_status: "on_hold")
                       when "assigned" then entries.where(assigned_to_type: "User", task_status: "assigned")
                       else
                         return render json: { error: "#{tab_name} is not a recognized tab name." }
                       end

    render json: pagination_json(filtered_entries)
  end
end
