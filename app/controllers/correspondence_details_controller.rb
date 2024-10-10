# frozen_string_literal: true

class CorrespondenceDetailsController < CorrespondenceController
  include CorrespondenceControllerConcern

  before_action :correspondence_details_access

  def correspondence_details
    set_instance_variables

    # Sort the response letters
    @correspondence_response_letters = sort_response_letters(
      @correspondence_details[:correspondence][:correspondenceResponseLetters]
    )

    respond_to do |format|
      format.html
      format.json { render json: build_json_response, status: :ok }
    end
  end

  def create_response_letter_for_correspondence
    updated_correspondences = correspondence_intake_processor.create_letter(params, current_user)

    if updated_correspondences.is_a?(Array) && updated_correspondences.any?
      updated_correspondence = updated_correspondences.first

      correspondence = Correspondence.find_by(id: updated_correspondence.correspondence_id)

      if correspondence

        serialized_response_letters = WorkQueue::CorrespondenceResponseLetterSerializer
          .new(correspondence.correspondence_response_letters)
          .serializable_hash[:data]

        response_letters = serialized_response_letters.map { |letter| letter[:attributes] }
        sorted_response_letters = sort_response_letters(response_letters)

        render json: { responseLetters: sorted_response_letters }, status: :ok
      else
        render json: { error: "Correspondence not found" }, status: :not_found
      end
    else
      render json: { error: "No response letter created" }, status: :unprocessable_entity
    end
  end

  def set_instance_variables
    @correspondence = serialized_correspondence

    # Group related variables into a single hash
    @correspondence_details = {
      organizations: current_user.organizations.pluck(:name),
      correspondence: @correspondence,
      correspondence_documents: @correspondence[:correspondenceDocuments],
      general_information: general_information,
      mail_tasks: mail_tasks,
      appeals_information: appeals,
      inbound_ops_team_users: User.inbound_ops_team_users.select(:css_id).pluck(:css_id),
      correspondence_types: CorrespondenceType.all
    }
  end

  def serialized_correspondence
    WorkQueue::CorrespondenceSerializer
      .new(correspondence)
      .serializable_hash[:data][:attributes]
      .merge(general_information)
      .merge(mail_tasks)
      .merge(appeals)
      .merge(all_correspondences)
      .merge(prior_mail)
      .merge(user_access)
  end

  def user_access
    user_access = if current_user.inbound_ops_team_supervisor? || current_user.inbound_ops_team_superuser?
                    "admin_access"
                  elsif current_user.inbound_ops_team_user?
                    "user_access"
                  end
    { user_access: user_access }
  end

  def build_json_response
    {
      correspondence: @correspondence_details[:correspondence],
      general_information: @correspondence_details[:general_information],
      mailTasks: @correspondence_details[:mail_tasks],
      corres_docs: @correspondence_details[:correspondence_documents]
    }
  end

  def correspondence_params
    params.require(:correspondence).permit(:correspondence, :va_date_of_receipt, :correspondence_type_id, :notes)
  end

  def edit_general_information
    correspondence.update!(
      va_date_of_receipt: correspondence_params[:va_date_of_receipt],
      correspondence_type_id: correspondence_params[:correspondence_type_id],
      notes: correspondence_params[:notes]
    )
    render json: { correspondence: serialized_correspondence }, status: :created
  end

  # Overriding method to allow users to access the correspondence details page
  def verify_correspondence_access
    true
  end

  def correspondence_details_access
    access_redirect unless correspondence.status == Constants.CORRESPONDENCE_STATUSES.pending ||
                           correspondence.status == Constants.CORRESPONDENCE_STATUSES.completed
  end

  def access_redirect
    if !InboundOpsTeam.singleton.user_has_access?(current_user)
      redirect_to "/queue"
    elsif current_user.inbound_ops_team_supervisor? || current_user.inbound_ops_team_superuser?
      redirect_to "/queue/correspondence/team"
    elsif current_user.inbound_ops_team_user?
      redirect_to "/queue/correspondence"
    else
      redirect_to "/unauthorized"
    end
  end

  def update_correspondence
    if correspondence_intake_processor.update_correspondence(params)
      render json: {}, status: :created
    else
      render json: { error: "Failed to update records" }, status: :bad_request
    end
  end

  def create_correspondence_relations
    params[:priorMailIds]&.map do |corr_id|
      CorrespondenceRelation.create!(
        correspondence_id: corr_id,
        related_correspondence_id: @correspondence.id
      )
    end
  end

  def save_correspondence_appeals
    if params[:selected_appeal_ids].present?
      params[:selected_appeal_ids].each do |appeal_id|
        @correspondence.correspondence_appeals.find_or_create_by(appeal_id: appeal_id)
      end
    end
    if params[:unselected_appeal_ids].present?
      correspondence_appeals_to_delete = @correspondence.correspondence_appeals
        .where(appeal_id: params[:unselected_appeal_ids])

      CorrespondencesAppealsTask.where(correspondence_appeal_id: correspondence_appeals_to_delete.pluck(:id)).delete_all

      correspondence_appeals_to_delete.delete_all
    end
    respond_to do |format|
      format.html
      format.json { render json: @correspondence.appeal_ids, status: :ok }
    end
  end

  def waive_evidence_submission_window_task
    appeal = Appeal.find_by_uuid(params[:appeal_uuid])
    return render json: { error: "Appeal not found" }, status: :not_found unless appeal

    correspondence_appeal = @correspondence.correspondence_appeals.find_by(appeal_id: appeal.id)
    return render json: { error: "Correspondence appeal not found" }, status: :not_found unless correspondence_appeal

    # Create a new EvidenceSubmissionWindowTask and associate it with the correspondence appeal
    ActiveRecord::Base.transaction do
      remaining_time = Time.parse(params[:task][:remaining_time])
      assigned_at = remaining_time

      task = EvidenceSubmissionWindowTask.create!(
        appeal: appeal,
        parent: appeal.root_task,
        assigned_to: MailTeam.singleton,
        assigned_at: assigned_at,
        instructions: params[:task][:instructions]

      )
      CorrespondencesAppealsTask.create!(correspondence_appeal: correspondence_appeal, task: task)
    end

    render json: { correspondence: serialized_correspondence }, status: :created
  end

  private

  def sort_response_letters(response_letters)
    response_letters.sort_by do |letter|
      days_left = letter[:days_left]

      sort_key = if days_left.match?(/Expired on/)
                   expiration_date = Date.strptime(days_left.split("Expired on ").last, "%m/%d/%Y")
                   [0, expiration_date, letter[:date_sent].to_date, letter[:title]]
                 elsif days_left.match?(/No response window/)
                   [2, letter[:date_sent].to_date, letter[:title]]
                 else
                   expiration_date_str = days_left.split(" (").first
                   expiration_date = Date.strptime(expiration_date_str, "%m/%d/%Y")
                   [1, expiration_date, letter[:date_sent].to_date, letter[:title]]
                 end
      sort_key
    end
  end

  def appeals
    appeals = Appeal.where(veteran_file_number: @correspondence.veteran.file_number)

    serialized_appeals = appeals.map do |appeal|
      WorkQueue::CorrespondenceDetailsAppealSerializer.new(appeal).serializable_hash[:data][:attributes]
    end

    { appeals_information: serialized_appeals }
  end

  def mail_tasks
    {
      mailTasks: @correspondence.correspondence_mail_tasks.completed.map(&:label)
    }
  end

  def all_correspondences
    { all_correspondences: serialized_correspondences }
  end

  def serialized_correspondences
    serialized_data.map { |correspondence| correspondence[:attributes] }
  end

  def serialized_data
    serializer = WorkQueue::CorrespondenceDetailsSerializer.new(ordered_correspondences)
    serializer.serializable_hash[:data]
  end

  def ordered_correspondences
    @correspondence.veteran.correspondences.order(va_date_of_receipt: :asc)
  end

  def prior_mail
    prior_mail = Correspondence.prior_mail(veteran_by_correspondence.id, correspondence.uuid).order(:va_date_of_receipt)
      .select { |corr| corr.status == "Completed" || corr.status == "Pending" }
    serialized_mail = prior_mail.map do |correspondence|
      WorkQueue::CorrespondenceDetailsSerializer.new(correspondence).serializable_hash[:data][:attributes]
    end

    { prior_mail: serialized_mail }
  end
end
