# frozen_string_literal: true

class CorrespondenceDetailsController < CorrespondenceController
  include CorrespondenceControllerConcern

  def correspondence_details
    @organizations = current_user.organizations.pluck(:name)
    @correspondence = serialized_correspondence
    set_instance_variables

    respond_to do |format|
      format.html
      format.json { render json: build_json_response, status: :ok }
    end
  end

  def set_instance_variables
    @inbound_ops_team_users = User.inbound_ops_team_users.select(:css_id).pluck(:css_id)
    @correspondence_types = CorrespondenceType.all
    @correspondence = serialized_correspondence
  end

  def serialized_correspondence
    WorkQueue::CorrespondenceSerializer
      .new(correspondence)
      .serializable_hash[:data][:attributes]
      .merge(general_information)
      .merge(mail_tasks)
      .merge(appeals)
  end

  def build_json_response
    {
      correspondence: @correspondence,
      general_information: general_information,
      mailTasks: mail_tasks,
      corres_docs: @correspondence[:correspondenceDocuments]
    }
  end

  # overriding method to allow users to access the correspondence details page
  def verify_correspondence_access
    true
  end

  private

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
end

