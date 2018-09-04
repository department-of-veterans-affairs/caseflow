describe VsoTask do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".create_tasks_for_appeal!" do
    let(:participant_id_with_pva) { "1234" }
    let(:participant_id_with_aml) { "5678" }

    let(:appeal) do
      create(:appeal, claimants: [
               create(:claimant, participant_id: participant_id_with_pva),
               create(:claimant, participant_id: participant_id_with_aml)
             ])
    end

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
        .with([participant_id_with_aml]).and_return(
          participant_id_with_aml => {
            representative_name: "VIETNAM VETERANS OF AMERICA",
            representative_type: "POA National Organization",
            participant_id: "2452415"
          }
        )
    end

    context "when VSOs exist in our organization table" do
      let!(:pva) do
        Vso.create(
          name: "Paralyzed Veterans Of America",
          feature: "vso_queue_pva",
          role: "VSO",
          url: "paralyzed-veterans-of-america",
          participant_id: "2452383"
        )
      end

      let!(:vva) do
        Vso.create(
          name: "Vietnam Veterans Of America",
          feature: "vso_queue_vva",
          role: "VSO",
          url: "vietnam-veterans-of-america",
          participant_id: "2452415"
        )
      end

      it "creates a task for each VSO" do
        VsoTask.create_tasks_for_appeal!(appeal)
        expect(VsoTask.count).to eq(2)
        expect(VsoTask.first.assigned_to).to eq(pva)
        expect(VsoTask.second.assigned_to).to eq(vva)
      end
    end

    context "when VSO doesn't exist in our organization table" do
      it "throws an error" do
        expect { VsoTask.create_tasks_for_appeal!(appeal) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
