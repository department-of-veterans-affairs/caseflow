# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength

# Contains most of the logic inside of CorrespondenceController
module CorrespondenceControllerConcern
  private

  MAX_QUEUED_ITEMS = 60

  def process_tasks_if_applicable(inbound_ops_team_user, task_ids, tab)
    # candidate for refactor using PATCH request
    return unless inbound_ops_team_user && task_ids.present?

    set_banner_params(inbound_ops_team_user, task_ids.count, tab)
    update_tasks(inbound_ops_team_user, task_ids)
  end

  def update_tasks(inbound_ops_team_user, task_ids)
    return unless @response_type == "success"

    tasks = Task.where(id: task_ids)
    tasks.update_all(
      assigned_to_id: inbound_ops_team_user.id,
      assigned_to_type: "User",
      status: Constants.TASK_STATUSES.assigned
    )
  end

  def set_banner_params(user, task_count, tab)
    template = message_template(user, task_count, tab)
    response_type(user, task_count)
    @response_header = template[:header]
    @response_message = template[:message]
  end

  def message_template(user, task_count, tab)
    case tab
    when "correspondence_unassigned"
      bulk_assignment_banner_text(user, task_count)
    when "correspondence_team_assigned"
      bulk_assignment_banner_text(user, task_count, action_prefix: "re")
    end
  end

  def bulk_assignment_banner_text(user, task_count, action_prefix: "")
    success_header_unassigned = "You have successfully #{action_prefix}"\
      "assigned #{task_count} Correspondence to #{user.css_id}."
    failure_header_unassigned = "Correspondence #{action_prefix}assignment to #{user.css_id} could not be completed"
    success_message = "Please go to your individual queue to see any self-assigned correspondence."
    failure_message = "Queue volume has reached maximum capacity for this user."
    user_tasks = user&.tasks&.length
    {
      header: (user_tasks + task_count <= MAX_QUEUED_ITEMS) ? success_header_unassigned : failure_header_unassigned,
      message: (user_tasks + task_count <= MAX_QUEUED_ITEMS) ? success_message : failure_message
    }
  end

  def response_type(user, task_count)
    current_user_tasks = user&.tasks&.length
    @response_type = (current_user_tasks + task_count <= MAX_QUEUED_ITEMS) ? "success" : "warning"
  end

  def set_flash_intake_success_message
    # intake error message is handled in client/app/queue/correspondence/intake/components/CorrespondenceIntake.jsx
    vet = veteran_by_correspondence
    flash[:correspondence_intake_success] = [
      "You have successfully submitted a correspondence record for #{vet.name}(#{vet.file_number})",
      "The mail package has been uploaded to the Veteran's eFolder as well."
    ]
  end

  def intake_cancel_message(action_type)
    vet = veteran_by_correspondence
    if action_type == "cancel_intake"
      @response_header = "You have successfully cancelled the intake form"
      @response_message = "#{vet.name}'s correspondence (ID: #{correspondence.id}) "\
       "has been returned to the supervisor's queue for assignment."
    else
      @response_header = "You have successfully saved the intake form"
      @response_message = "You can continue from step three of the intake form for #{vet.name}'s "\
      "correspondence (ID: #{correspondence.id}) at a later date."
    end
    @response_type = "success"
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
    @correspondence = Correspondence.find_by(uuid: params[:correspondence_uuid])
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

  def upload_documents_to_claim_evidence
    rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)
    correspondence_documents_efolder_uploader.upload_documents_to_claim_evidence(correspondence, current_user, rpt)
  end
end
# rubocop:enable Metrics/ModuleLength
