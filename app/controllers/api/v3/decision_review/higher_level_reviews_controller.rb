# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewsController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    # create a new HigherLevelReviewIntake and return the serialized version
    # add a route for this
    render plain: 'blah'
  end
end