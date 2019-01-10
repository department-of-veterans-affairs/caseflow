describe EvidenceSubmissionWindowTask do
  let(:participant_id_with_pva) { "000000" }
  let(:participant_id_with_no_vso) { "000000" }

  before do
    allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
      .with([participant_id_with_pva]).and_return(
        participant_id_with_pva => {
          representative_name: "PARALYZED VETERANS OF AMERICA, INC.",
          representative_type: "POA National Organization",
          participant_id: "2452383"
        }
      )
    allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
      .with([participant_id_with_no_vso]).and_return({})
  end
  let(:appeal) do
    create(:appeal, docket_type: "evidence_submission", claimants: [
             create(:claimant, participant_id: participant_id_with_pva)
           ])
  end
  let(:appeal_no_vso) do
    create(:appeal, docket_type: "evidence_submission", claimants: [
             create(:claimant, participant_id: participant_id_with_no_vso)
           ])
  end

  context "on complete" do
    it "creates an ihp task if the appeal has a vso" do
      RootTask.create_root_and_sub_tasks!(appeal)
      expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq(0)
      EvidenceSubmissionWindowTask.find_by(appeal: appeal).update!(status: "completed")
      expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq(1)
      expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
    end

    it "marks appeal as ready for distribution if the appeal doesn't have a vso" do
      RootTask.create_root_and_sub_tasks!(appeal_no_vso)
      EvidenceSubmissionWindowTask.find_by(appeal: appeal).update!(status: "completed")
      expect(DistributionTask.first(appeal: appeal).status).to eq("in_progress")
    end
  end
end
