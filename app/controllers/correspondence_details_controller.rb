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
        @correspondence.correspondence_appeals.create!(appeal_id: appeal_id)
      end
    end
    if params[:unselected_appeal_ids].present?
      @correspondence.correspondence_appeals
        .where(appeal_id: params[:unselected_appeal_ids])
        .delete_all
    end
    respond_to do |format|
      format.html
      format.json { render json: @correspondence.appeal_ids, status: :ok }
    end
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
    case_search_results = CaseSearchResultsForCaseflowVeteranId.new(
      caseflow_veteran_ids: [@correspondence.veteran_id], user: current_user
    ).search_call

    { appeals_information: case_search_results.extra[:case_search_results] }
  end

  def mail_tasks
    {
      mailTasks: @correspondence.correspondence_mail_tasks.completed.map(&:label)
    }
  end

  def all_correspondences
    { all_correspondences: ordered_correspondences }
  end

  def ordered_correspondences
    @correspondence.veteran.correspondences.order(va_date_of_receipt: :asc).select(
      :id,
      :va_date_of_receipt,
      :nod,
      :uuid,
      :notes
    )
  end

  def prior_mail
    prior_mail = Correspondence.prior_mail(veteran_by_correspondence.id, correspondence.uuid).order(:va_date_of_receipt)
      .select { |corr| corr.status == "Completed" || corr.status == "Pending" }
    serialized_mail = prior_mail.map do |correspondence|
      WorkQueue::CorrespondenceSerializer.new(correspondence).serializable_hash[:data][:attributes]
    end

    { prior_mail: serialized_mail }
  end
end
