# frozen_string_literal: true

# :reek:RepeatedConditional
class CorrespondenceController < ApplicationController
  include CorrespondenceControllerUtil
  before_action :verify_correspondence_access
  before_action :verify_feature_toggle
  before_action :correspondence
  before_action :auto_texts
  before_action :veteran_information

  def mail_team_users
    mail_team_users = User.mail_team_users
    respond_to do |format|
      format.json do
        render json: { mail_team_users: mail_team_users }
      end
    end
  end

  def veteran
    render json: { veteran_id: veteran_by_correspondence&.id, file_number: veteran_by_correspondence&.file_number }
  end

  def current_correspondence
    @current_correspondence ||= correspondence
  end

  def veteran_information
    @veteran_information ||= veteran_by_correspondence
  end

  private

  def handle_mail_superuser_or_supervisor
    set_handle_mail_superuser_or_supervisor_params(current_user, params)
    mail_team_user = User.find_by(css_id: params[:user].strip) if params[:user].present?
    task_ids = params[:taskIds]&.split(",") if params[:taskIds].present?
    tab = params[:tab] if params[:tab].present?

    respond_to do |format|
      format.html { handle_html_response(mail_team_user, task_ids, tab) }
      format.json { handle_json_response(mail_team_user, task_ids, tab) }
    end
  end

  def handle_reassign_or_remove_task(mail_team_user)
    return unless @reassign_remove_task_id.present? && @action_type.present?

    task = Task.find(@reassign_remove_task_id)
    mail_team_user ||= task.assigned_by

    reassign_remove_banner_action(mail_team_user)
    render "correspondence_team"
  end

  def demo_data
    json_file_path = "vbms doc types.json"
    JSON.parse(File.read(json_file_path))
  end

  def handle_json_response(mail_team_user, task_ids, tab)
    if mail_team_user && task_ids.present?
      set_banner_params(mail_team_user, task_ids&.count, tab)
    else
      render json: { correspondence_config: CorrespondenceConfig.new(assignee: InboundOpsTeam.singleton) }
    end
  end

  def verify_correspondence_access
    return true if InboundOpsTeam.singleton.user_has_access?(current_user) ||
                   MailTeam.singleton.user_has_access?(current_user) ||
                   BvaIntake.singleton.user_is_admin?(current_user) ||
                   MailTeam.singleton.user_is_admin?(current_user)

    redirect_to "/unauthorized"
  end

  def verify_feature_toggle
    if !FeatureToggle.enabled?(:correspondence_queue) && verify_correspondence_access
      redirect_to "/under_construction"
    elsif !FeatureToggle.enabled?(:correspondence_queue) || !verify_correspondence_access
      redirect_to "/unauthorized"
    end
  end
end
