# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    # new HigherLevelReview and return the serialized version
    mock_hlr = HigherLevelReview.new(uuid: 'FAKEuuid-mock-test-fake-mocktestdata')
    # TODO return an IntakeStatus object
    render json: {data: {type: 'high_level_review', id: mock_hlr.uuid, attributes: mock_hlr.attributes}}, status: 202 # TODO add serializer for intake
  rescue => e
    render plain: e.message
  end

private
  def intake_status(hlr)
    #FIXME get this order right
    #REVIEW should this be in asyncable?
    if hlr.processed?
      :processed
    elsif hlr.attempted?
      :attempted
    elsif hlr.submitted?
      :submitted
    elsif hlr.cancelled?
      :cancelled
    end
  end
end