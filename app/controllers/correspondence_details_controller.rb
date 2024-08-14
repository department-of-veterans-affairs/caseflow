# frozen_string_literal: true

class CorrespondenceDetailsController < CorrespondenceController
  include CorrespondenceControllerConcern

  def correspondence_details
    set_instance_variables

    # Sort the response letters
    @correspondence_response_letters = sort_response_letters(@correspondence_details[:correspondence][:correspondenceResponseLetters])

    respond_to do |format|
      format.html
      format.json { render json: build_json_response, status: :ok }
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
  end

  def build_json_response
    {
      correspondence: @correspondence_details[:correspondence],
      general_information: @correspondence_details[:general_information],
      mailTasks: @correspondence_details[:mail_tasks],
      corres_docs: @correspondence_details[:correspondence_documents]
    }
  end

  # overriding method to allow users to access the correspondence details page
  def verify_correspondence_access
    true
  end

  private

  def sort_response_letters(response_letters)
    response_letters.sort_by do |letter|
      case letter[:days_left]
      when /Expired on:/
        expiration_date = Date.strptime(letter[:days_left].split(" on ").last, "%m/%d/%Y")
        [0, expiration_date]
      when /No response window/
        [2, 0]
      else
        [1, 0]
      end
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
    { all_correspondences: serialized_correspondences }
  end

  def serialized_correspondences
    serialized_data.map { |correspondence| correspondence[:attributes] }
  end

  def serialized_data
    serializer = WorkQueue::CorrespondenceSerializer.new(ordered_correspondences)
    serializer.serializable_hash[:data]
  end

  def ordered_correspondences
    @correspondence.veteran.correspondences.order(va_date_of_receipt: :asc)
  end
end
