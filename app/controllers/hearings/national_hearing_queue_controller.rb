# frozen_string_literal: true

class Hearings::NationalHearingQueueController < ApplicationController
  include GenericTaskPaginationConcern

  def index
    respond_to do |format|
      format.html { render "national_hearing_queue/index" }
      format.json { queue_entries }
    end
  end

  private

  def allowed_params
    params.permit(
      :tab,
      :search_query,
      { filter: [] },
      :page    )
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
