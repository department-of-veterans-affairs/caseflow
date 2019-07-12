# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    mock_hlr = HigherLevelReview.new(uuid: 'FAKEuuid-mock-test-fake-mocktestdata')
    render json: intake_status(hlr), status: 202 # TODO add serializer for intake
  rescue => e
    render plain: e.message
  end

private
  def intake_status(higher_level_review)
    {
      data: {
        type: 'IntakeStatus',
        id: higher_level_review.uuid,
        attributes: {
          status: async_status(higher_level_review)
        }
      }
    }
  end

  def async_status(higher_level_review)
    #REVIEW should this be in asyncable?
    if higher_level_review.processed?
      :processed
    elsif higher_level_review.cancelled?
      :cancelled
    elsif higher_level_review.attempted?
      :attempted
    elsif higher_level_review.submitted?
      :submitted
    end
  end
end