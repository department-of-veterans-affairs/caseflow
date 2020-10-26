# frozen_string_literal: true

describe Api::V3::DecisionReviews::Appeals::ContestableIssuesController, :postgres, type: :request do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:api_v3_appeals_contestable_issues)

    Timecop.freeze(post_ama_start_date)
  end

  after { FeatureToggle.disable!(:api_v3_appeals_contestable_issues) }

  let(:decision_review_type) { :appeal }
  let(:source) do
    appeal = create(decision_review_type, veteran_file_number: veteran.file_number)
    create(:root_task, :completed, appeal: appeal)
    appeal
  end
  let(:benefit_type) { nil }

  include_examples "contestable issues index requests"
end
