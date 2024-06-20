# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength

# Contains most of the logic inside of CorrespondenceController
module CorrespondenceControllerConcern
  private

  def process_tasks_if_applicable(mail_team_user, task_ids, tab)
    # candidate for refactor using PATCH request
    return unless mail_team_user && task_ids.present?

    # Instantiate AutoAssignableUserFinder with current_user
    permission_checker = AutoAssignableUserFinder.new(mail_team_user)
    errors = []

    task_ids.each do |id|
      correspondence_task = Task.find(id)&.correspondence
      check_result = permission_checker.can_user_work_this_correspondence?(
        user: mail_team_user,
        correspondence: correspondence_task
      )

      if check_result
        update_task(mail_team_user, id)
      else
        errors << permission_checker.unassignable_reason
      end
    end

    set_banner_params(mail_team_user, errors, task_ids.count, tab)
  end

  def update_task(mail_team_user, task_id)
    task = Task.find_by(id: task_id)
    task.update(
      assigned_to_id: mail_team_user.id,
      assigned_to_type: "User",
      status: Constants.TASK_STATUSES.assigned
    )
  end

  def set_banner_params(user, errors, task_count, tab)
    template = message_template(user, errors, task_count, tab)
    @response_type = errors.empty? ? "success" : "warning"
    @response_header = template[:header]
    @response_message = template[:message]
  end

  def message_template(user, errors, task_count, tab)
    case tab
    when "correspondence_unassigned"
      bulk_assignment_banner_text(user, errors, task_count)
    when "correspondence_team_assigned"
      bulk_assignment_banner_text(user, errors, task_count, action_prefix: "re")
    end
  end

  def bulk_assignment_banner_text(user, errors, task_count, action_prefix: "")
    success_header_unassigned = "You have successfully #{action_prefix}"\
      "assigned #{task_count} Correspondence to #{user.css_id}."
    failure_header_unassigned = "Correspondence was not #{action_prefix}assigned to #{user.css_id}"
    success_message = "Please go to your individual queue to see any self-assigned correspondence."
    failure_message = errors.uniq.join(", ")
    {
      header: errors.empty? ? success_header_unassigned : failure_header_unassigned,
      message: errors.empty? ? success_message : failure_message
    }
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
