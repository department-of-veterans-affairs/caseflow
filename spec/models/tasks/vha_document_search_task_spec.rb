describe VhaDocumentSearchTask, :postgres do  
  let(:camo) { VhaCamo.singleton }
  let(:caregiver) { VhaCaregiverSupport.singleton }
  

  context "camo user" do
    let(:task) { create(:vha_document_search_task, assigned_to: camo) }
    let(:user) { create(:user) }
    before { camo.add_user(user) }

    describe "feature toggle" do
      it "when feature toggle is disabled" do
        FeatureToggle.disable!(:vha_predocket_workflow)
        task.available_actions(user) { is_expected.to match_array [] }
      end
    end

    describe ".label" do
      before { FeatureToggle.enable!(:vha_predocket_workflow) }
      after { FeatureToggle.disable!(:vha_predocket_workflow) }
      it "uses a friendly label" do
        expect(task.class.label).to eq COPY::REVIEW_DOCUMENTATION_TASK_LABEL        
      end
    end

    describe "#available_actions" do
      before { FeatureToggle.enable!(:vha_predocket_workflow) }
      after { FeatureToggle.disable!(:vha_predocket_workflow) }
      subject { task.available_actions(user) }
      it { is_expected.to eq VhaDocumentSearchTask::VHA_CAMO_TASK_ACTIONS }
      it { is_expected.not_to eq VhaDocumentSearchTask::VHA_CAREGIVER_SUPPORT_TASK_ACTIONS }
    end   
  end

  context "caregiver user" do
    let(:task) { create(:vha_document_search_task, assigned_to: caregiver) }
    let(:user) { create(:user) }
    before { caregiver.add_user(user) }

    describe "feature toggle" do
      it "when feature toggle is disabled" do
        FeatureToggle.disable!(:vha_predocket_workflow)
        task.available_actions(user) { is_expected.to match_array [] }
      end
    end

    describe ".label" do
      before { FeatureToggle.enable!(:vha_predocket_workflow) }
      after { FeatureToggle.disable!(:vha_predocket_workflow) }
      it "uses a friendly label" do
        expect(task.class.label).to eq COPY::REVIEW_DOCUMENTATION_TASK_LABEL
      end
    end

    describe "#available_actions" do
      before { FeatureToggle.enable!(:vha_predocket_workflow) }
      after { FeatureToggle.disable!(:vha_predocket_workflow) }
      subject { task.available_actions(user) }     
      it { is_expected.to eq VhaDocumentSearchTask::VHA_CAREGIVER_SUPPORT_TASK_ACTIONS }
      it { is_expected.not_to eq VhaDocumentSearchTask::VHA_CAMO_TASK_ACTIONS }      
    end
  end
end
