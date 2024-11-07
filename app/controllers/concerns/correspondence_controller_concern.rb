# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
# :reek:DataClump

# Contains most of the logic inside of CorrespondenceController
module CorrespondenceControllerConcern
  private

  # :reek:FeatureEnvy
  def process_tasks_if_applicable(mail_team_user, task_ids, tab)
    # candidate for refactor using PATCH request
    return unless mail_team_user && task_ids.present?

    # Instantiate AutoAssignableUserFinder with current_user
    permission_checker = AutoAssignableUserFinder.new(mail_team_user)

    # iterate through each task and check if the user can work the correspondence
    task_ids.each do |id|
      correspondence = Task.find(id)&.correspondence
      check_result = permission_checker.can_user_work_this_correspondence?(
        user: mail_team_user,
        correspondence: correspondence
      )

      # assign the task if the user can work the correspondence
      update_task(mail_team_user, id) if check_result
    end

    # use permission_checker.unassignable_reasons errors to generate the banner
    set_banner_params(
      mail_team_user,
      permission_checker.unassignable_reasons,
      task_ids.count,
      tab
    )
  end

  def update_task(mail_team_user, task_id)
    task = Task.find_by(id: task_id)
    task.update(
      assigned_to_id: mail_team_user.id,
      assigned_to_type: "User",
      status: Constants.TASK_STATUSES.assigned
    )
  end

  # :reek:LongParameterList
  def set_banner_params(user, errors, task_count, tab)
    template = message_template(user, errors, task_count, tab)
    @response_type = errors.empty? ? "success" : "warning"
    @response_header = template[:header]
    @response_message = template[:message]
  end

  # :reek:ControlParameter and :reek:LongParameterList
  def message_template(user, errors, task_count, tab)
    case tab
    when "correspondence_unassigned"
      if task_count == 1
        single_assignment_banner_text(user, errors, task_count)
      else
        multiple_assignment_banner_text(user, errors, task_count)
      end
    when "correspondence_team_assigned"
      if task_count == 1
        single_assignment_banner_text(user, errors, task_count, action_prefix: "re")
      else
        multiple_assignment_banner_text(user, errors, task_count, action_prefix: "re")
      end
    end
  end

  # :reek:FeatureEnvy
  def single_assignment_banner_text(*args, action_prefix: "")
    success_header_unassigned = "You have successfully #{action_prefix}"\
      "assigned #{args[2]} Correspondence to #{args[0].css_id}."
    failure_header_unassigned = "Correspondence was not #{action_prefix}assigned to #{args[0].css_id}"
    success_message = "Please go to your individual queue to see any self-assigned correspondence."

    failure_message = build_single_error_message(action_prefix, error_reason(args[1][0]))

    {
      header: args[1].empty? ? success_header_unassigned : failure_header_unassigned,
      message: args[1].empty? ? success_message : failure_message
    }
  end

  # :reek:FeatureEnvy
  def multiple_assignment_banner_text(*args, action_prefix: "")
    success_header = "You have successfully #{action_prefix}"\
    "assigned #{args[2]} Correspondences to #{args[0].css_id}."
    success_message = "Please go to your individual queue to see any self-assigned correspondences."
    failure_header = "Not all correspondence were #{action_prefix}assigned to #{args[0].css_id}"

    failure_message = build_multi_error_message(args[1], action_prefix)

    # return JSON message
    {
      header: args[1].blank? ? success_header : failure_header,
      message: args[1].blank? ? success_message : failure_message.join(" \n")
    }
  end

  # :reek:FeatureEnvy
  def build_multi_error_message(errors, action_prefix)
    failure_message = []

    # Get error counts
    error_counts = {
      Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.NOD_ERROR => errors.count(
        Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.NOD_ERROR
      ),
      Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.SENSITIVITY_ERROR => errors.count(
        Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.SENSITIVITY_ERROR
      ),
      Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.CAPACITY_ERROR => errors.count(
        Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.CAPACITY_ERROR
      )
    }

    error_counts.each do |error, count|
      if count.positive?
        multiple_errors = error_counts.values.count(&:positive?) > 1
        failure_message << build_error_message(count, action_prefix, error_reason(error), multiple_errors)
      end
    end

    failure_message
  end

  def error_reason(error)
    return "" unless error.is_a?(String)

    case error
    when Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.NOD_ERROR then "of NOD permissions settings"
    when Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.SENSITIVITY_ERROR then "of sensitivity level mismatch"
    when Constants.CORRESPONDENCE_AUTO_ASSIGN_ERROR.CAPACITY_ERROR then "maximum capacity has been reached for user's
                                                                        queue"
    end
  end

  def build_single_error_message(action_prefix, reason)
    # Build error message for single correspondence based on error types
    "Case was not #{action_prefix}assigned to user because #{reason}."
  end

  def build_error_message(*args)
    # Build error message for multiple correspondence based on error types
    message = "#{args[0]} cases were not #{args[1]}assigned to user"
    message = "• #{message}" if args[3].present?
    message += " because #{args[2]}." unless args[0].zero?
    message
  end

  def set_flash_intake_success_message
    # intake error message is handled in client/app/queue/correspondence/intake/components/CorrespondenceIntake.jsx
    vet = veteran_by_correspondence
    flash[:correspondence_intake_success] = [
      "You have successfully submitted a correspondence record for #{vet.name}(#{vet.file_number})",
      "The mail package has been uploaded to the Veteran's eFolder as well."
    ]
  end

  # :reek:ControlParameter
  def intake_cancel_message(action_type)
    vet = veteran_by_correspondence
    if action_type == "cancel_intake"
      @response_header = "You have successfully cancelled the intake form"
      @response_message = "#{vet.name}'s correspondence "\
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
