# frozen_string_literal: true

describe BusinessLineReporter, :postgres do
  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:user) { create(:default_user) }

  let(:veteran_a) { create(:veteran, first_name: "Aaa") }
  let(:veteran_b) { create(:veteran, first_name: "Bbb") }
  let(:hlr_a) { create(:higher_level_review, veteran_file_number: veteran_a.file_number) }
  let(:hlr_b) { create(:higher_level_review, veteran_file_number: veteran_b.file_number) }

  let!(:request_issue_a) { create(:request_issue, :rating, decision_review: hlr_a) }
  let!(:request_issue_b) { create(:request_issue, :rating, decision_review: hlr_b) }

  let(:today) { Time.zone.now }
  let(:last_week) { Time.zone.now - 7.days }

  let!(:completed_tasks) do
    [
      create(:higher_level_review_task,
             :completed,
             appeal: hlr_a,
             assigned_to: non_comp_org,
             closed_at: last_week),
      create(:higher_level_review_task,
             :completed,
             appeal: hlr_b,
             assigned_to: non_comp_org,
             closed_at: today)
    ]
  end

  subject { described_class.new(non_comp_org).as_csv }

  describe "displays tasks page" do
    it "returns a CSV-formatted string" do
      csv = subject.as_csv
      binding.pry
      expect(csv)
        .to match(/SupplementalClaim,\d+,#{6.days.ago},#{6.days.ago},#{7.days.ago},bad,#{veteran.participant_id}/)
      expect(CSV.parse(csv).count).to eq(7) # jobs + header
    end
  end
end
