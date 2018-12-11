describe LegacyIssueOptin do
  context "async logic scopes" do
    let!(:legacy_issue_optin_requiring_processing) do
      create(:legacy_issue_optin).tap(&:submit_for_processing!)
    end

    let!(:legacy_issue_optin_processed) do
      create(:legacy_issue_optin).tap(&:processed!)
    end

    let!(:legacy_issue_optin_recently_attempted) do
      create(
        :legacy_issue_optin,
        attempted_at: (LegacyIssueOptin::REQUIRES_PROCESSING_RETRY_WINDOW_HOURS - 1).hours.ago
      )
    end

    let!(:legacy_issue_optin_attempts_ended) do
      create(
        :legacy_issue_optin,
        submitted_at: (LegacyIssueOptin::REQUIRES_PROCESSING_WINDOW_DAYS + 5).days.ago,
        attempted_at: (LegacyIssueOptin::REQUIRES_PROCESSING_WINDOW_DAYS + 1).days.ago
      )
    end

    context ".unexpired" do
      it "matches inside the processing window" do
        expect(described_class.unexpired).to eq([legacy_issue_optin_requiring_processing])
      end
    end

    context ".processable" do
      it "matches eligible for processing" do
        expect(described_class.processable).to match_array(
          [legacy_issue_optin_requiring_processing, legacy_issue_optin_attempts_ended]
        )
      end
    end

    context ".attemptable" do
      it "matches could be attempted" do
        expect(described_class.attemptable).not_to include(legacy_issue_optin_recently_attempted)
      end
    end

    context ".requires_processing" do
      it "matches must still be processed" do
        expect(described_class.requires_processing).to eq([legacy_issue_optin_requiring_processing])
      end
    end

    context ".expired_without_processing" do
      it "matches unfinished but outside the retry window" do
        expect(described_class.expired_without_processing).to eq([legacy_issue_optin_attempts_ended])
      end
    end
  end

  context "#perform!" do
    before do
      RequestStore[:current_user] = user
    end

    let(:vacols_case_issue) { create(:case_issue) }
    let(:vacols_case_issue2) { create(:case_issue) }
    let(:vacols_case) { create(:case, :status_advance, case_issues: [vacols_case_issue, vacols_case_issue2]) }
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let(:user) { Generators::User.build }
    let(:request_issue) do
      create(:request_issue, vacols_id: vacols_case_issue.isskey, vacols_sequence_id: vacols_case_issue.issseq)
    end
    let(:issue) { Issue.load_from_vacols(vacols_case_issue.reload.attributes) }

    subject { create(:legacy_issue_optin, request_issue: request_issue) }

    it "closes VACOLS issue with disposition O" do
      subject.perform!

      vacols_case_issue.reload
      vacols_case.reload
      expect(vacols_case_issue.issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
      expect(issue.disposition).to eq(:ama_soc_ssoc_opt_in)
      expect(issue).to be_closed
      expect(vacols_case).to_not be_closed
      expect(subject).to be_processed
    end

    context "VACOLS case has no more open issues" do
      let(:vacols_case) { create(:case, :status_advance, case_issues: [vacols_case_issue]) }

      it "also closes VACOLS case with disposition O" do
        subject.perform!

        vacols_case_issue.reload
        vacols_case.reload
        expect(vacols_case).to be_closed
        expect(vacols_case.bfdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
        expect(issue.disposition).to eq(:ama_soc_ssoc_opt_in)
        expect(issue).to be_closed
        expect(subject).to be_processed
      end
    end
  end
end
