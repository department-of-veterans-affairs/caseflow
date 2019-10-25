# frozen_string_literal: true

class Api::V3::DecisionReview::IssuesController < Api::V3::BaseController
  def index
    render plain: 'so many issues'
  end
end
