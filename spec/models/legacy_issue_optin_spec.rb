# frozen_string_literal: true

describe LegacyIssueOptin, :all_dbs do
  let(:remand_issue) { create(:case_issue, :disposition_remanded, issseq: 1) }
  let(:remand_case) do
    create(:case, :status_remand, bfkey: "remand", case_issues: [remand_issue])
  end
  let(:lio) { create(:legacy_issue_optin, request_issue: request_issue) }
  let(:request_issue) { create(:request_issue, vacols_id: remand_case.bfkey, vacols_sequence_id: remand_issue.issseq) }

  describe ".related_remand_issues" do
    it "joins with request_issues" do
      expect(described_class.related_remand_issues(lio.vacols_id).count).to eq(1)
      expect(described_class.related_remand_issues(lio.vacols_id).first).to eq(lio)
    end
  end
end
