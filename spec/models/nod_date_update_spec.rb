# frozen_string_literal: true

describe NodDateUpdate, :all_dbs do
  let(:timely_request_issue) { create(:request_issue, decision_date: 381.days.ago) }
  let(:untimely_request_issue_with_exemption) do
    create(:request_issue,
           decision_date: 2.years.ago,
           untimely_exemption: true)
  end
  let(:request_issues) { [timely_request_issue, untimely_request_issue_with_exemption] }
  let(:appeal) { create(:appeal, request_issues: request_issues) }
  let(:nod_date_update) { build(:nod_date_update, appeal: appeal) }

  context "validate_all_issues_timely" do
    subject { nod_date_update.validate_all_issues_timely }

    it "should return false if timely issue without exemption becomes untimely" do
      subject

      expect(nod_date_update.errors[:new_date][0][:message]).to include(
        "Timeliness of one or more issues is affected by NOD date change"
      )
      expect(nod_date_update.errors[:new_date][0][:affected_issues].first.id).to equal(1)
      expect(nod_date_update.errors[:new_date][0][:unaffected_issues].first.id).to equal(2)
    end

    it "should return true if untimely issue has exemption status" do
      nod_date_update.new_date = 391.days.ago
      subject
      expect(nod_date_update.errors[:new_date]).to match_array([])
    end
  end
end
