# frozen_string_literal: true

describe CorrespondenceDocumentsEfolderUploader do
  subject(:described) { described_class.new }

  let(:veteran) { create(:veteran) }
  let(:correspondence) { create(:correspondence, :with_single_doc, veteran_id: veteran.id, uuid: SecureRandom.uuid) }
  let(:current_user) { create(:intake_user) }
  let(:parent_task) { create(:correspondence_intake_task, appeal: correspondence, assigned_to: current_user) }

  describe "#upload_documents_to_claim_evidence" do
    context "with ClaimEvidenceService doc upload success" do
      before do
        doc = correspondence.correspondence_documents.first

        expect(FeatureToggle).to receive(:enabled?).with(:ce_api_demo_toggle).and_return(true)
        expect(ExternalApi::ClaimEvidenceService).to receive(:upload_document)
          .with(doc.pdf_location, veteran.file_number, doc.claim_evidence_upload_hash).once
      end

      it "succeeds and does not create any EfolderUploadFailedTask tasks" do
        result = nil

        expect do
          result = described.upload_documents_to_claim_evidence(correspondence, current_user, parent_task)
        end.not_to change(EfolderUploadFailedTask, :count)

        expect(result).to eq(true)
      end
    end

    context "with ClaimEvidenceService doc upload failure" do
      before do
        expect(FeatureToggle).to receive(:enabled?).with(:ce_api_demo_toggle).and_return(false)
        expect(ExternalApi::ClaimEvidenceService).not_to receive(:upload_document)
        expect(Rails.logger).to receive(:error).with(/Mock failure for upload in non-prod env/)
      end

      it "fails and creates a EfolderUploadFailedTask task" do
        result = nil

        expect do
          result = described.upload_documents_to_claim_evidence(correspondence, current_user, parent_task)
        end.to change(EfolderUploadFailedTask, :count)

        expect(result).to eq(false)

        failed_task = EfolderUploadFailedTask.last
        expect(failed_task.appeal_id).to eq(correspondence.id)
        expect(failed_task.assigned_to).to eq(current_user)
        expect(failed_task.parent_id).to eq(parent_task.id)
        expect(failed_task.instructions[0]).to include("Mock failure for upload in non-prod env")
      end

      context "with existing EfolderUploadFailedTask" do
        # rubocop:disable Layout/LineLength
        let!(:existing_failed_task) { create(:efolder_upload_failed_task, appeal: correspondence, appeal_type: "Correspondence") }
        # rubocop:enable Layout/LineLength
        it "does not create a new EfolderUploadFailedTask if one already exists" do
          expect do
            described.upload_documents_to_claim_evidence(correspondence, current_user, parent_task)
          end.not_to change(EfolderUploadFailedTask, :count)
        end
      end
    end
  end
end
