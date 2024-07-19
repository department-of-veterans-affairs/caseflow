# frozen_string_literal: true

class CorrespondenceDetailsController < CorrespondenceController
  include CorrespondenceControllerConcern

  def correspondence_details
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
  end

  def build_json_response
    {
      correspondence: @correspondence,
      general_information: general_information,
      corres_docs: @correspondence[:correspondenceDocuments],
      taskInstructions: task_instructions
    }
  end
end
