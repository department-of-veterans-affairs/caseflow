# frozen_string_literal: true

describe Api::V3::DecisionReview::IssuesController, type: :request do
  describe "#index" do
    it 'should return a 200 OK'
    it 'should return a list of issues'
    it 'should return a 404 when the veteran is not found'
    it 'should return a 422 when the receipt date is bad'
  end
end
