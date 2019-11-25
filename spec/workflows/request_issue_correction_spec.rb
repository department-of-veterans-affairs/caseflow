# frozen_string_literal: true

describe "Request Issue Correction", :postgres do
  let(:veteran) do
    create(:veteran,
           first_name: "Ed",
           last_name: "Merica")
  end

  let(:claim_review) do
    create(:higher_level_review, veteran_file_number: veteran.file_number, receipt_date: 2.weeks.ago)
  end

  let(:correction) do
    RequestIssueCorrection.new(
      review: claim_review,
      corrected_request_issue_ids: corrected_request_issue_ids,
      request_issues_data: request_issues_data
    )
  end

  let(:request_issues_data) { [] }
  let(:corrected_request_issue_ids) { nil }
  let(:request_issue1) { create(:request_issue, decision_review: claim_review) }
  let(:request_issue2) { create(:request_issue, decision_review: claim_review) }

  describe "#corrected_issues" do
    subject { correction.corrected_issues }

    context "when corrected request issue ids are present" do
      let(:corrected_request_issue_ids) { [request_issue1.id, request_issue2.id] }

      it { is_expected.to eq([request_issue1, request_issue2]) }
    end

    context "when corrected request issue ids are not present" do
      let(:request_issues_data) do
        [
          { request_issue_id: request_issue1.id, correction_type: "control" },
          { request_issue_id: request_issue2.id }
        ]
      end

      it { is_expected.to eq([request_issue1]) }
    end
  end

  describe "#call" do
    subject { correction.call }

    context "when request contains correction types" do
      let(:request_issues_data) do
        [
          { request_issue_id: request_issue1.id, correction_type: "control" },
          { request_issue_id: request_issue2.id, correction_type: "control" }
        ]
      end

      it "should create correction issues" do
        subject
        expect(claim_review.request_issues.count).to eq 4
        expect(correction.correction_issues.size).to eq 2
      end
    end
  end
end
