# frozen_string_literal: true

class CorrespondenceQueueController < CorrespondenceController
  def correspondence_cases
    if current_user.inbound_ops_team_supervisor?
      redirect_to "/queue/correspondence/team"
    elsif current_user.inbound_ops_team_superuser? || current_user.inbound_ops_team_user?
      intake_cancel_message(action_type) if %w[continue_later cancel_intake].include?(action_type)
      respond_to do |format|
        format.html {}
        format.json do
          render json: { correspondence_config: CorrespondenceConfig.new(assignee: current_user) }
        end
      end
    else
      redirect_to "/unauthorized"
    end
  end

  def correspondence_team
    if current_user.inbound_ops_team_superuser? || current_user.inbound_ops_team_supervisor?
      correspondence_team_response
    elsif current_user.inbound_ops_team_user?
      redirect_to "/queue/correspondence"
    else
      redirect_to "/unauthorized"
    end
  end

  private

  def correspondence_team_response
    inbound_ops_team_user = User.find_by(css_id: params[:user].strip) if params[:user].present?
    task_ids = params[:task_ids]&.split(",") if params[:task_ids].present?
    tab = params[:tab] if params[:tab].present?

    respond_to do |format|
      format.html do
        @inbound_ops_team_users = User.inbound_ops_team_users.pluck(:css_id)
        @inbound_ops_team_non_admin = User.inbound_ops_team_users.select(&:inbound_ops_team_user?).pluck(:css_id)
        correspondence_team_html_response(inbound_ops_team_user, task_ids, tab)
      end
      format.json { correspondence_team_json_response }
    end
  end

  def correspondence_team_json_response
    render json: { correspondence_config: CorrespondenceConfig.new(assignee: InboundOpsTeam.singleton) }
  end

  def correspondence_team_html_response(inbound_ops_team_user, task_ids, tab)
    if inbound_ops_team_user && task_ids.present?
      # candidate for refactor using PATCH request
      process_tasks_if_applicable(inbound_ops_team_user, task_ids, tab)
    elsif %w[continue_later cancel_intake].include?(action_type)
      intake_cancel_message(action_type)
    end
  end

  def action_type
    params[:userAction].strip if params[:userAction].present?
  end
end
