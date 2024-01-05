# frozen_string_literal: true

describe CorrespondenceIntakeProcessor do
  subject(:described) { described_class.new }

  let(:veteran) { create(:veteran) }
  let(:correspondence) { create(:correspondence, veteran_id: veteran.id, uuid: SecureRandom.uuid) }
  let(:current_user) { create(:intake_user) }

  describe "#upload_documents_to_claim_evidence" do
    context "ClaimEvidenceService doc upload success" do
      before do
        expect(FeatureToggle).to receive(:enabled?).with(:ce_api_demo_toggle).and_return(true)
      end

      it "succeeds and does not create any EfolderUploadFailedTask tasks" do
        result = described.upload_documents_to_claim_evidence(correspondence, current_user)

        expect(result).to eq(true)
        expect(EfolderUploadFailedTask.count).to eq(0)
      end
    end

    context "ClaimEvidenceService doc upload failure" do
      before do
        expect(FeatureToggle).to receive(:enabled?).with(:ce_api_demo_toggle).and_return(false)
      end

      it "fails and creates a EfolderUploadFailedTask task" do
        result = described.upload_documents_to_claim_evidence(correspondence, current_user)

        expect(result).to eq(false)

        failed_task = EfolderUploadFailedTask.last
        expect(failed_task.appeal_id).to eq(correspondence.id)
        expect(failed_task.assigned_to).to eq(current_user)
      end
    end
  end
end
