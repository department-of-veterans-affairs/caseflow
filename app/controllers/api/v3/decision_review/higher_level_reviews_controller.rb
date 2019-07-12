# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    mock_hlr = HigherLevelReview.new(
      uuid: 'FAKEuuid-mock-test-fake-mocktestdata',
      establishment_submitted_at: Time.zone.now # having this timestamp marks it as submitted
    )
    render json: intake_status(mock_hlr), status: 202
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
    elsif higher_level_review.canceled?
      :canceled
    elsif higher_level_review.attempted?
      :attempted
    elsif higher_level_review.submitted?
      :submitted
    end
  end
end