# frozen_string_literal: true

class TaskTreeController < ApplicationController
  def show
    return render_access_error unless FeatureToggle.enabled?(:appeal_viz, user: current_user)

    return render_access_error unless BGSService.new.can_access?(appeal.veteran_file_number)

    no_cache

    respond_to do |format|
      format.html { render layout: "plain_application" }
      format.text { render plain: appeal.structure_render(tasks, *Task.column_names) }
      format.json { render json: { task_tree: task_tree_as_json } }
    end
  end

  private

  helper_method :appeal, :task_tree_as_json

  def task_tree_as_json
    @task_tree_as_json ||= appeal.structure_as_json(tasks, *Task.column_names)
  end

  def appeal
    @appeal ||= fetch_appeal
  end

  def tasks
    @tasks ||= FeatureToggle.enabled?(:eager_task_loading) ? tasks_by_appeal.load : tasks_by_appeal.to_a
  end

  def tasks_by_appeal
    @tasks_by_appeal ||= Task.where(appeal_id: appeal.id)
  end

  def fetch_appeal
    if legacy_appeal?
      LegacyAppeal.find_or_create_by_vacols_id(appeal_id)
    elsif Appeal::UUID_REGEX.match?(appeal_id)
      Appeal.find_by(uuid: appeal_id)
    else
      Appeal.find(appeal_id)
    end
  end

  def appeal_id
    params[:appeal_id]
  end

  def appeal_type
    params[:appeal_type]
  end

  def legacy_appeal?
    appeal_type == "LegacyAppeal"
  end

  def render_access_error
    render(Caseflow::Error::ActionForbiddenError.new(
      message: COPY::ACCESS_DENIED_TITLE
    ).serialize_response)
  end
end
