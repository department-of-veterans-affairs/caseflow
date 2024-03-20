# frozen_string_literal: true

# :reek:RepeatedConditional
class CorrespondenceController < ApplicationController
  before_action :verify_correspondence_access
  before_action :verify_feature_toggle
  before_action :correspondence
  before_action :auto_texts
  before_action :veteran_information
  MAX_QUEUED_ITEMS = 60

  def intake
    # If correspondence intake was started, json data from the database will
    # be loaded into the page when user returns to intake
    @redux_store ||= CorrespondenceIntake.find_by(user: current_user,
                                                  correspondence: current_correspondence)&.redux_store

    respond_to do |format|
      format.html { return render "correspondence/intake" }
      format.json do
        render json: {
          currentCorrespondence: current_correspondence,
          correspondence: correspondence_load,
          veteranInformation: veteran_information
        }
      end
    end
  end

  def current_step
    intake = CorrespondenceIntake.find_by(user: current_user, correspondence: current_correspondence) ||
             CorrespondenceIntake.new(user: current_user, correspondence: current_correspondence)

    intake.update(
      current_step: params[:current_step],
      redux_store: params[:redux_store]
    )

    if intake.valid?
      intake.save!

      render(json: {}, status: :ok) && return
    else
      render(json: intake.errors.full_messages, status: :unprocessable_entity) && return
    end
  end

  def correspondence_cases
    if current_user.mail_supervisor?
      redirect_to "/queue/correspondence/team"
    elsif current_user.mail_superuser? || current_user.mail_team_user?
      respond_to do |format|
        format.html { "your_correspondence" }
        format.json do
          render json: { correspondence_config: CorrespondenceConfig.new(assignee: current_user) }
        end
      end
    else
      redirect_to "/unauthorized"
    end
  end

  def mail_team_users
    mail_team_users = User.mail_team_users
    respond_to do |format|
      format.json do
        render json: { mail_team_users: mail_team_users }
      end
    end
  end

  def correspondence_team
    if current_user.mail_superuser? || current_user.mail_supervisor?
      handle_mail_superuser_or_supervisor
    elsif current_user.mail_team_user?
      redirect_to "/queue/correspondence"
    else
      redirect_to "/unauthorized"
    end
  end

  def review_package
    render "correspondence/review_package"
  end

  def intake_update
    begin
      intake_appeal_update_tasks
      if FeatureToggle.enabled?(:ce_api_demo_toggle)
        upload_documents_to_claim_evidence
      end
      render json: { correspondence: correspondence }
    rescue StandardError => error
      Rails.logger.error(error.to_s)
      Raven.capture_exception(error)
      render json: {}, status: :bad_request
    end
  end

  def veteran
    render json: { veteran_id: veteran_by_correspondence&.id, file_number: veteran_by_correspondence&.file_number }
  end

  def package_documents
    packages = PackageDocumentType.all
    render json: { package_document_types: packages }
  end

  def current_correspondence
    @current_correspondence ||= correspondence
  end

  def veteran_information
    @veteran_information ||= veteran_by_correspondence
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
    veteran = Veteran.find_by(file_number: veteran_params["file_number"])
    if veteran && correspondence.update(
      correspondence_params.merge(
        veteran_id: veteran.id,
        updated_by_id: RequestStore.store[:current_user].id
      )
    )
      correspondence.tasks.map do |task|
        if task.type == "ReviewPackageTask"
          task.status = "in_progress"
          task.save
        end
      end
      render json: { status: :ok }
    else
      render json: { error: "Please enter a valid Veteran ID" }, status: :unprocessable_entity
    end
  end

  def update_cmp
    correspondence.update(
      va_date_of_receipt: params["VADORDate"].in_time_zone,
      package_document_type_id: params["packageDocument"]["value"].to_i
    )
    correspondence.tasks.map do |task|
      if task.type == "ReviewPackageTask"
        task.status = "in_progress"
        task.save
      end
    end
    render json: { status: 200, correspondence: correspondence }
  end

  def document_type_correspondence
    data = vbms_document_types
    render json: { data: data }
  end

  def pdf
    # Hard-coding Document access until CorrespondenceDocuments are uploaded to S3Bucket
    document = Document.limit(200)[params[:pdf_id].to_i]

    document_disposition = "inline"
    if params[:download]
      document_disposition = "attachment; filename='#{params[:type]}-#{params[:id]}.pdf'"
    end

    # The line below enables document caching for a month.
    expires_in 30.days, public: true
    send_file(
      document.serve,
      type: "application/pdf",
      disposition: document_disposition
    )
  end

  def process_intake
    if correspondence_intake_processor.process_intake(params, current_user)
      set_flash_intake_success_message
      render json: {}, status: :created
    else
      render json: { error: "Failed to update records" }, status: :bad_request
    end
  end

  private

  def set_handle_mail_superuser_or_supervisor_params
    @mail_team_users = User.mail_team_users.pluck(:css_id)
    @is_superuser = current_user.mail_superuser?
    @is_supervisor = current_user.mail_supervisor?
    @reassign_remove_task_id = params[:taskId].strip if params[:taskId].present?
    @action_type = params[:userAction].strip if params[:userAction].present?
  end

  def handle_mail_superuser_or_supervisor
    set_handle_mail_superuser_or_supervisor_params
    mail_team_user = User.find_by(css_id: params[:user].strip) if params[:user].present?
    task_ids = params[:taskIds]&.split(",") if params[:taskIds].present?
    tab = params[:tab] if params[:tab].present?

    respond_to do |format|
      format.html { handle_html_response(mail_team_user, task_ids, tab) }
      format.json { handle_json_response(mail_team_user, task_ids, tab) }
    end
  end

  def reassign_remove_banner_action(mail_team_user)
    operation_type = params[:operation]
    begin
      case operation_type
      when "reassign"
        update_reassign_task(mail_team_user)
      when "remove"
        update_remove_task(mail_team_user)
      end
      set_reassign_remove_banner_params(mail_team_user, operation_type)
    rescue StandardError
      set_error_banner_params(operation_type, mail_team_user)
    end
  end

  def handle_html_response(mail_team_user, task_ids, tab)
    if mail_team_user && task_ids.present?
      process_tasks_if_applicable(mail_team_user, task_ids, tab)
      handle_reassign_or_remove_task(mail_team_user)
    end
  end

  def process_tasks_if_applicable(mail_team_user, task_ids, tab)
    return unless mail_team_user && task_ids.present?

    set_banner_params(mail_team_user, task_ids.count, tab)
    update_tasks(mail_team_user, task_ids)
  end

  def handle_reassign_or_remove_task(mail_team_user)
    return unless @reassign_remove_task_id.present? && @action_type.present?

    task = Task.find(@reassign_remove_task_id)
    mail_team_user ||= task.assigned_by

    reassign_remove_banner_action(mail_team_user)
    render "correspondence_team"
  end

  def handle_json_response(mail_team_user, task_ids, tab)
    if mail_team_user && task_ids.present?
      set_banner_params(mail_team_user, task_ids&.count, tab)
    else
      render json: { correspondence_config: CorrespondenceConfig.new(assignee: InboundOpsTeam.singleton) }
    end
  end

  def update_tasks(mail_team_user, task_ids)
    return unless @response_type == "success"

    tasks = Task.where(id: task_ids)
    tasks.update_all(assigned_to_id: mail_team_user.id, assigned_to_type: "User", status: "assigned")
  end

  def approve_reassign_task(task, current_user, mail_team_user)
    task.update!(
      completed_by: current_user,
      assigned_to_id: current_user,
      assigned_to: current_user,
      closed_at: Time.zone.now,
      status: "completed"
    )
    parent_task = ReviewPackageTask.find(task.parent_id)
    parent_task.update!(
      status: "completed",
      closed_at: Time.zone.now,
      completed_by: current_user
    )
    ReviewPackageTask.create!(
      assigned_to: mail_team_user,
      assigned_to_id: mail_team_user.id,
      status: "assigned",
      appeal_id: task.appeal_id,
      appeal_type: "Correspondence"
    )
  end

  def approve_remove_task(task_id, current_user, mail_team_user)
    Task.find_by(id: task_id).update!(
      completed_by_id: current_user,
      assigned_to_id: mail_team_user,
      assigned_to: mail_team_user,
      status: "cancelled"
    )
  end

  def reject_remove_task(task_id, current_user, decision_reason)
    Task.find_by(id: task_id).update!(
      completed_by_id: current_user,
      closed_at: Time.zone.now,
      status: "completed",
      instructions: decision_reason
    )
    ReviewPackageTask.find(Task.find_by(id: task_id).parent_id).update!(status: "in_progress")
  end

  def reject_reassign_task(task, current_user)
    decision_reason = params[:decisionReason].strip
    task.update(
      completed_by_id: current_user,
      closed_at: Time.zone.now,
      status: "completed",
      instructions: decision_reason
    )
    parent_task = ReviewPackageTask.find(task.parent_id)
    parent_task.update(assigned_to_type: "User", status: "in_progress")
  end

  def update_reassign_task(mail_team_user)
    task_id = params[:taskId].strip

    task = Task.find_by(id: task_id)
    case @action_type
    when "approve"
      approve_reassign_task(task, current_user, mail_team_user)
    when "reject"
      reject_reassign_task(task, current_user)
    end
  end

  def update_remove_task(mail_team_user)
    task_id = params[:taskId].strip
    decision_reason = params[:decisionReason].strip
    case @action_type
    when "approve"
      approve_remove_task(task_id, current_user, mail_team_user)
    when "reject"
      reject_remove_task(task_id, current_user, decision_reason)
    end
  end

  def set_banner_params(user, task_count, tab)
    template = message_template(user, task_count, tab)
    response_type(user)
    @response_header = template[:header]
    @response_message = template[:message]
  end

  def set_reassign_remove_banner_params(user, operation_type)
    case operation_type
    when "remove"
      template = remove_message_template(user)
      @response_header = template[:header]
      @response_message = template[:message]
      @response_type = "success"
    when "reassign"
      template = reassign_message_template(user)
      @response_header = template[:header]
      @response_message = template[:message]
      @response_type = "success"
    end
  end

  def set_error_banner_params(operation_type, mail_team_user)
    operation_verb = operation_type == "approve" ? "approved" : "rejected"
    @response_header = "Package request for #{mail_team_user.css_id} could not be #{operation_verb}"
    @response_message = "Please try again at a later time or contact the Help Desk."
    @response_type = "error"
  end

  def handle_correspondence_unassigned_response(user, task_count)
    success_header_unassigned = "You have successfully assigned #{task_count} Correspondence to #{user.css_id}."
    failure_header_unassigned = "Correspondence assignment to #{user.css_id} has failed"
    success_message = "Please go to your individual queue to see any self-assigned correspondence."
    failure_message = "Queue volume has reached maximum capacity for this user."
    {
      header: (user.tasks.length < MAX_QUEUED_ITEMS) ? success_header_unassigned : failure_header_unassigned,
      message: (user.tasks.length < MAX_QUEUED_ITEMS) ? success_message : failure_message
    }
  end

  def handle_correspondence_assigned_response(user, task_count)
    success_header_assigned = "You have successfully reassigned #{task_count} Correspondence to #{user.css_id}."
    failure_header_assigned = "Correspondence reassignment to #{user.css_id} has failed"
    success_message = "Please go to your individual queue to see any self-assigned correspondence."
    failure_message = "Queue volume has reached maximum capacity for this user."
    {
      header: (user.tasks.length < MAX_QUEUED_ITEMS) ? success_header_assigned : failure_header_assigned,
      message: (user.tasks.length < MAX_QUEUED_ITEMS) ? success_message : failure_message
    }
  end

  def message_template(user, task_count, tab)
    case tab
    when "correspondence_unassigned"
      handle_correspondence_unassigned_response(user, task_count)
    when "correspondence_team_assigned"
      handle_correspondence_assigned_response
    end
  end

  def reassign_message_template(user)
    success_header_reassigned = "You have successfully reassigned a mail record for #{user.css_id}"
    success_message_reassigned = "Please go to your individual queue to see any self assigned correspondence."
    success_header_rejected = "You have successfully rejected a package request for #{user.css_id}"
    success_message_rejected = "The package will be re-assigned to the user that sent the request."
    case @action_type
    when "approve"
      {
        header: success_header_reassigned,
        message: success_message_reassigned
      }
    when "reject"
      {
        header: success_header_rejected,
        message: success_message_rejected
      }
    end
  end

  def remove_message_template(user)
    success_header_approved = "You have successfully removed a mail package for #{user.css_id}"
    success_message_approved = "The package has been removed from Caseflow and must be manually uploaded again
     from the Centralized Mail Portal, if it needs to be processed."
    success_header_rejected = "You have successfully rejected a package request for #{user.css_id}"
    success_message_rejected = "The package will be re-assigned to the user that sent the request."

    case @action_type
    when "approve"
      {
        header: success_header_approved,
        message: success_message_approved
      }
    when "reject"
      {
        header: success_header_rejected,
        message: success_message_rejected
      }
    end
  end

  def response_type(user)
    @response_type = (user.tasks.length < MAX_QUEUED_ITEMS) ? "success" : "warning"
  end

  # :reek:FeatureEnvy
  def vbms_document_types
    begin
      data = ExternalApi::ClaimEvidenceService.document_types
    rescue StandardError => error
      Rails.logger.error(error.full_message)
      data ||= demo_data
    end
    data.map { |document_type| { id: document_type["id"], name: document_type["description"] } }
  end

  def demo_data
    json_file_path = "vbms doc types.json"
    JSON.parse(File.read(json_file_path))
  end

  def set_flash_intake_success_message
    # intake error message is handled in client/app/queue/correspondence/intake/components/CorrespondenceIntake.jsx
    vet = veteran_by_correspondence
    flash[:correspondence_intake_success] = [
      "You have successfully submitted a correspondence record for #{vet.name}(#{vet.file_number})",
      "The mail package has been uploaded to the Veteran's eFolder as well."
    ]
  end

  def verify_correspondence_access
    return true if InboundOpsTeam.singleton.user_has_access?(current_user) ||
                   MailTeam.singleton.user_has_access?(current_user) ||
                   BvaIntake.singleton.user_is_admin?(current_user) ||
                   MailTeam.singleton.user_is_admin?(current_user)

    redirect_to "/unauthorized"
  end

  def general_information
    vet = veteran_by_correspondence
    {
      notes: correspondence.notes,
      file_number: vet.file_number,
      veteran_name: vet.name,
      correspondence_type_id: correspondence.correspondence_type_id,
      correspondence_types: CorrespondenceType.all,
      correspondence_tasks: correspondence.tasks.map do |task|
        WorkQueue::CorrespondenceTaskSerializer.new(task).serializable_hash[:data][:attributes]
      end
    }
  end

  def correspondence_params
    params.require(:correspondence).permit(:notes, :correspondence_type_id)
  end

  def veteran_params
    params.require(:veteran).permit(:file_number)
  end

  def verify_feature_toggle
    if !FeatureToggle.enabled?(:correspondence_queue) && verify_correspondence_access
      redirect_to "/under_construction"
    elsif !FeatureToggle.enabled?(:correspondence_queue) || !verify_correspondence_access
      redirect_to "/unauthorized"
    end
  end

  def correspondence
    return @correspondence if @correspondence.present?

    if params[:id].present?
      @correspondence = Correspondence.find(params[:id])
    elsif params[:correspondence_uuid].present?
      @correspondence = Correspondence.find_by(uuid: params[:correspondence_uuid])
    end

    @correspondence
  end

  def correspondence_load
    Correspondence.where(veteran_id: veteran_by_correspondence.id).where.not(uuid: params[:correspondence_uuid])
  end

  def veteran_by_correspondence
    return nil if correspondence&.veteran_id.blank?

    @veteran_by_correspondence ||= Veteran.find_by(id: correspondence.veteran_id)
  end

  def veterans_with_correspondences
    veterans = Veteran.includes(:correspondences).where(correspondences: { id: Correspondence.select(:id) })
    veterans.map { |veteran| vet_info_serializer(veteran, veteran.correspondences.last) }
  end

  def auto_texts
    @auto_texts ||= AutoText.all.pluck(:name)
  end

  def vet_info_serializer(veteran, correspondence)
    {
      firstName: veteran.first_name,
      lastName: veteran.last_name,
      fileNumber: veteran.file_number,
      cmPacketNumber: correspondence.cmp_packet_number,
      correspondenceUuid: correspondence.uuid,
      packageDocumentType: correspondence.correspondence_type_id
    }
  end

  def correspondence_intake_processor
    @correspondence_intake_processor ||= CorrespondenceIntakeProcessor.new
  end

  def correspondence_documents_efolder_uploader
    @correspondence_documents_efolder_uploader ||= CorrespondenceDocumentsEfolderUploader.new
  end

  # :reek:FeatureEnvy
  def intake_appeal_update_tasks
    tasks = Task.where("appeal_id = ? and appeal_type = ?", correspondence.id, "Correspondence")
    tasks.map do |task|
      if task.type == "ReviewPackageTask"
        task.instructions.push("An appeal intake was started because this Correspondence is a 10182")
        task.assigned_to_id = correspondence.assigned_by_id
        task.assigned_to = User.find(correspondence.assigned_by_id)
      end
      task.status = "cancelled"
      task.save
    end
  end

  def upload_documents_to_claim_evidence
    rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)
    correspondence_documents_efolder_uploader.upload_documents_to_claim_evidence(correspondence, current_user, rpt)
  end
end
