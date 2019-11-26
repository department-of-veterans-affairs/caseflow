# frozen_string_literal: true

describe RampIssue, :postgres do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:review) do
    create(:ramp_election,
           veteran_file_number: "64205555",
           notice_date: 3.days.ago,
           receipt_date: 2.days.ago)
  end

  let(:description) { nil }
  let(:ramp_issue) { RampIssue.new(description: description) }

  context "#source_issue_id=" do
    subject { ramp_issue.source_issue_id = source_issue.id }

    let(:source_issue) do
      RampIssue.create!(review: review, description: "Source description")
    end

    context "description wasn't set" do
      it "sets description from source issue" do
        subject
        expect(ramp_issue.description).to eq("Source description")
      end
    end

    context "description was set" do
      let(:description) { "Fresh" }

      it "doesn't set description from source issue" do
        subject
        expect(ramp_issue.description).to eq("Fresh")
      end
    end
  end
end
