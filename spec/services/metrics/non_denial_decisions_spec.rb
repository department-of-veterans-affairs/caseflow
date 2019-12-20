# frozen_string_literal: true

describe Metrics::NonDenialDecisions, :postgres do
  let(:user) { create(:user) }
  let(:start_date) { Time.zone.now - 31.days }
  let(:end_date) { Time.zone.now - 1.day }
  let(:date_range) { Metrics::DateRange.new(start_date, end_date) }
  let(:number_of_decisions_in_range) { 25 }
  let(:number_of_end_products_created_in_7_days) { 5 }
  before do
    decision_issues = (1...number_of_decisions_in_range).map do
      appeal = create(:appeal, :outcoded, decision_documents: [create(:decision_document)])
      BvaDispatchTask.create_from_root_task(appeal.root_task).update(assigned_to: user)
      create(:decision_issue, decision_review: appeal)
    end

    decision_issues.sample(number_of_end_products_created_in_7_days).each do |decision|
      create(:end_product_establishment, source: decision.decision_review.decision_documents.first)
    end

    decision_issue
  end

  subject { Metrics::NonDenialDecisions.new(date_range).call }

  it do
    expect(subject).to eq(number_of_end_products_created_in_7_days / number_of_decisions_in_range.to_float)
  end
end
