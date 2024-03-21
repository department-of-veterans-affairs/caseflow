# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength

# Contains most of the logic inside of CorrespondenceController
module CorrespondenceControllerUtil
  def current_correspondence
    @current_correspondence ||= correspondence
  end

  def veteran_information
    @veteran_information ||= veteran_by_correspondence
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

  def set_handle_mail_superuser_or_supervisor_params(current_user, params)
    @mail_team_users = User.mail_team_users.pluck(:css_id)
    @is_superuser = current_user.mail_superuser?
    @is_supervisor = current_user.mail_supervisor?
    @reassign_remove_task_id = params[:taskId].strip if params[:taskId].present?
    @action_type = params[:userAction].strip if params[:userAction].present?
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

  private

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

  def reassign_remove_task_id_and_action_type_present?
    if @reassign_remove_task_id.present? && @action_type.present?
      return true
    end

    false
  end

  def handle_html_response(mail_team_user, task_ids, tab)
    if reassign_remove_task_id_and_action_type_present?
      task = Task.find(@reassign_remove_task_id)
      if mail_team_user.nil?
        mail_team_user = task.assigned_by
      end
    end

    if mail_team_user && (task_ids.present? || @reassign_remove_task_id.present?)
      process_tasks_if_applicable(mail_team_user, task_ids, tab)
      handle_reassign_or_remove_task(mail_team_user)
    end
  end

  def process_tasks_if_applicable(mail_team_user, task_ids, tab)
    return unless mail_team_user && task_ids.present?

    set_banner_params(mail_team_user, task_ids.count, tab)
    update_tasks(mail_team_user, task_ids)
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
# rubocop:enable Metrics/ModuleLength
