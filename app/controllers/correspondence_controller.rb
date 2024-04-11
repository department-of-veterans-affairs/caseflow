# frozen_string_literal: true

# :reek:RepeatedConditional
class CorrespondenceController < ApplicationController
  include CorrespondenceControllerConcern
  before_action :verify_correspondence_access
  before_action :verify_feature_toggle
  before_action :correspondence
  before_action :auto_texts

  def mail_team_users
    mail_team_users = User.mail_team_users
    respond_to do |format|
      format.json do
        render json: { mail_team_users: mail_team_users }
      end
    end
  end

  def review_package
    @mail_team_users = User.mail_team_users.pluck(:css_id)
    render "correspondence/review_package"
  end

  def veteran
    render json: { veteran_id: veteran_by_correspondence&.id, file_number: veteran_by_correspondence&.file_number }
  end

  def package_documents
    packages = PackageDocumentType.all
    render json: { package_document_types: packages }
  end

  def show
    corres_docs = correspondence.correspondence_documents
    reason_remove = if RemovePackageTask.find_by(appeal_id: correspondence.id, type: RemovePackageTask.name).nil?
                      ""
                    else
                      RemovePackageTask.find_by(appeal_id: correspondence.id, type: RemovePackageTask.name).instructions
                    end
    response_json = {
      correspondence: correspondence,
      package_document_type: correspondence&.package_document_type,
      general_information: general_information,
      user_can_edit_vador: InboundOpsTeam.singleton.user_is_admin?(current_user),
      correspondence_documents: corres_docs.map do |doc|
        WorkQueue::CorrespondenceDocumentSerializer.new(doc).serializable_hash[:data][:attributes]
      end,
      efolder_upload_failed_before: EfolderUploadFailedTask.where(
        appeal_id: correspondence.id, type: "EfolderUploadFailedTask"
      ),
      reasonForRemovePackage: reason_remove
    }
    render({ json: response_json }, status: :ok)
  end

  def update
    unless update_veteran_on_correspondence
      return render(json: { error: "Please enter a valid Veteran ID" }, status: :unprocessable_entity)
    end
    update_open_review_package_tasks ? render(json: { status: :ok }) : render(json: { status: 500 })
  end

  def update_cmp
    correspondence.update(
      va_date_of_receipt: params["VADORDate"].in_time_zone,
      package_document_type_id: params["packageDocument"]["value"].to_i
    )
    update_open_review_package_tasks
    render json: { status: 200, correspondence: correspondence }
  end

  def document_type_correspondence
    data = vbms_document_types
    render json: { data: data }
  end

  def correspondence_team
    if current_user.mail_superuser? || current_user.mail_supervisor?
      correspondence_team_response
    elsif current_user.mail_team_user?
      redirect_to "/queue/correspondence"
    else
      redirect_to "/unauthorized"
    end
  end

  private

  def update_veteran_on_correspondence
    veteran = Veteran.find_by(file_number: veteran_params["file_number"])
    veteran && correspondence.update(
      correspondence_params.merge(
        veteran_id: veteran.id,
        updated_by_id: RequestStore.store[:current_user].id
      )
    )
  end

  def update_open_review_package_tasks
    correspondence.tasks.open.where(type: ReviewPackageTask.name).each do |task|
      task.update(status: Constants.TASK_STATUSES.in_progress)
    end
  end

  def correspondence_team_response
    mail_team_user = User.find_by(css_id: params[:user].strip) if params[:user].present?
    task_ids = params[:task_ids]&.split(",") if params[:task_ids].present?
    tab = params[:tab] if params[:tab].present?

    respond_to do |format|
      format.html do
        @mail_team_users = User.mail_team_users.pluck(:css_id)
        correspondence_team_html_response(mail_team_user, task_ids, tab)
      end
      format.json { correspondence_team_json_response }
    end
  end

  def correspondence_team_json_response
    render json: { correspondence_config: CorrespondenceConfig.new(assignee: InboundOpsTeam.singleton) }
  end

  def correspondence_team_html_response(mail_team_user, task_ids, tab)
    if mail_team_user && task_ids.present?
      process_tasks_if_applicable(mail_team_user, task_ids, tab)
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
