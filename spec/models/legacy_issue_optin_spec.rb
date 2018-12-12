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
end
