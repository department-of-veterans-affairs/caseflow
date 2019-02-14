describe EvidenceSubmissionWindowTask do
  let(:participant_id_with_pva) { "000000" }
  let(:participant_id_with_no_vso) { "11111" }

  before do
    FeatureToggle.enable!(:ama_acd_tasks)
  end
  after do
    FeatureToggle.disable!(:ama_acd_tasks)
  end

  let!(:receipt_date) { 2.days.ago }
  let!(:appeal) do
    create(:appeal, docket_type: "evidence_submission", receipt_date: receipt_date, claimants: [
             create(:claimant, participant_id: participant_id_with_pva)
           ])
  end
  let!(:appeal_no_vso) do
    create(:appeal, docket_type: "evidence_submission", claimants: [
             create(:claimant, participant_id: participant_id_with_no_vso)
           ])
  end

  before do
    Vso.create(
      name: "Paralyzed Veterans Of America",
      role: "VSO",
      url: "paralyzed-veterans-of-america",
      participant_id: "2452383"
    )

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

  context "on complete" do
    it "creates an ihp task if the appeal has a vso" do
      RootTask.create_root_and_sub_tasks!(appeal)
      expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq(0)
      EvidenceSubmissionWindowTask.find_by(appeal: appeal).when_timer_ends
      expect(InformalHearingPresentationTask.where(appeal: appeal).length).to eq(1)
      expect(DistributionTask.find_by(appeal: appeal).status).to eq("on_hold")
    end

    it "marks appeal as ready for distribution if the appeal doesn't have a vso" do
      RootTask.create_root_and_sub_tasks!(appeal_no_vso)
      EvidenceSubmissionWindowTask.find_by(appeal: appeal_no_vso).update!(status: "completed")
      expect(DistributionTask.find_by(appeal: appeal_no_vso).status).to eq("assigned")
    end
  end

  context "timer_delay" do
    let(:task) do
      EvidenceSubmissionWindowTask.create!(appeal: appeal, assigned_to: Bva.singleton)
    end

    it "is marked as complete and vso tasks are created in 90 days" do
      TaskTimerJob.perform_now
      expect(task.reload.status).to eq("assigned")

      Timecop.travel(receipt_date + 90.days) do
        TaskTimerJob.perform_now
        expect(task.reload.status).to eq("completed")
      end
    end
  end
end
