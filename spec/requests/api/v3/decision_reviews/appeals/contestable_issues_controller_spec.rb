# frozen_string_literal: true

describe Api::V3::DecisionReviews::Appeals::ContestableIssuesController, :postgres, type: :request do
  let(:decision_review_type) { :appeal }
  let(:source) do
    appeal = create(decision_review_type, veteran_file_number: veteran.file_number)
    create(:root_task, :completed, appeal: appeal)
    appeal
  end
  let(:benefit_type) { nil }

  include_examples "contestable issues index requests"
end
