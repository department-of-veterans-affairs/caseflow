# frozen_string_literal: true

class CorrespondenceDetailsController < CorrespondenceController
  include CorrespondenceControllerConcern
  include RunAsyncable

  before_action :correspondence

  def correspondence_details
    @correspondence = WorkQueue::CorrespondenceSerializer
      .new(correspondence)
      .serializable_hash[:data][:attributes]
    respond_to do |format|
      format.html {}
      format.json do
        render json: { correspondence: @correspondence, status: :ok }
      end
    end
  end
end
