# frozen_string_literal: true

describe LegacyIssueOptin, :all_dbs do
  let(:remand_issue) { create(:case_issue, :disposition_remanded, issseq: 1) }
  let(:remand_case) do
    create(:case, :status_remand, bfkey: "remand", case_issues: [remand_issue])
  end
  let(:optin_date) { Time.zone.now - 5.hours }
  let(:rollback_date) { nil }
  let(:lio) do
    create(
      :legacy_issue_optin,
      request_issue: request_issue,
      optin_processed_at: optin_date,
      rollback_processed_at: rollback_date
    )
  end
  let(:request_issue) { create(:request_issue, vacols_id: remand_case.bfkey, vacols_sequence_id: remand_issue.issseq) }

  describe ".opt_ins_for_related_remand_issues" do
    it "joins with request_issues" do
      expect(described_class.opt_ins_for_related_remand_issues(lio.vacols_id).count).to eq(1)
      expect(described_class.opt_ins_for_related_remand_issues(lio.vacols_id).first).to eq(lio)
    end

    context "the issue has not been opted in" do
      let(:optin_date) { nil }

      it "doesn't return non-opted-in issues" do
        expect(described_class.opt_ins_for_related_remand_issues(lio.vacols_id).count).to eq(0)
      end
    end
  end
end
