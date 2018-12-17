describe LegacyOptinManager do
  context "#process!" do
    before do
      RequestStore[:current_user] = user
    end

    let(:vacols_case_issue) { create(:case_issue) }
    let(:vacols_case_issue2) { create(:case_issue) }
    let(:vacols_case) { create(:case, :status_advance, case_issues: [vacols_case_issue, vacols_case_issue2]) }
    let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let(:user) { Generators::User.build }
    let(:request_issue) do
      create(:request_issue, vacols_id: vacols_case_issue.isskey, vacols_sequence_id: vacols_case_issue.issseq)
    end
    let(:issue) { Issue.load_from_vacols(vacols_case_issue.reload.attributes) }

    let!(:legacy_issue_optin) { create(:legacy_issue_optin, request_issue: request_issue) }
    let!(:appeal) { create(:appeal, request_issues: [request_issue]) }

    subject { LegacyOptinManager.new(decision_review: appeal) }

    it "closes VACOLS issue with disposition O" do
      subject.process!

      vacols_case_issue.reload
      vacols_case.reload
      expect(vacols_case_issue.issdc).to eq(LegacyOptinManager::VACOLS_DISPOSITION_CODE)
      expect(issue.disposition).to eq(:ama_soc_ssoc_opt_in)
      expect(issue).to be_closed
      expect(vacols_case).to_not be_closed
    end

    context "VACOLS case has no more open issues" do
      let(:vacols_case) { create(:case, :status_advance, case_issues: [vacols_case_issue]) }

      it "also closes VACOLS case with disposition O" do
        subject.process!

        vacols_case_issue.reload
        vacols_case.reload
        expect(vacols_case).to be_closed
        expect(vacols_case.bfdc).to eq(LegacyOptinManager::VACOLS_DISPOSITION_CODE)
        expect(issue.disposition).to eq(:ama_soc_ssoc_opt_in)
        expect(issue).to be_closed
      end
    end
  end
end
