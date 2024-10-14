# frozen_string_literal: true
require 'pry'

describe CorrespondenceIntakeProcessor do
  subject(:described) { described_class.new }

  let(:veteran) { create(:veteran) }
  let(:correspondence) { create(:correspondence, :with_single_doc, veteran_id: veteran.id, uuid: SecureRandom.uuid) }
  let(:current_user) { create(:intake_user) }
  let(:parent_task) { create(:correspondence_intake_task, appeal: correspondence, assigned_to: current_user) }

  let(:mock_doc_uploader) { instance_double(CorrespondenceDocumentsEfolderUploader) }

  let(:intake_params) do
    {
      correspondence_uuid: correspondence.uuid
    }
  end

  before do
    allow(CorrespondenceDocumentsEfolderUploader).to receive(:new).and_return(mock_doc_uploader)
  end

  describe "#process_intake" do
    context "with doc upload success" do
      before do
        expect(mock_doc_uploader).to receive(:upload_documents_to_claim_evidence)
          .with(correspondence, current_user, parent_task).and_return(true)
      end

      it "succeeds and completes the parent task and its children" do
        result = described.process_intake(intake_params, current_user)

        expect(result).to eq(true)
        expect(parent_task.reload.status).to eq("completed")
      end

      context "with transaction rollback" do
        before do
          expect(described).to receive(:create_correspondence_relations).and_raise(ActiveRecord::RecordInvalid)
        end

        it "rolls back the parent task's status" do
          result = described.process_intake(intake_params, current_user)

          expect(result).to eq(false)
          expect(parent_task.reload.status).not_to eq("completed")
        end
      end
    end

    context "with doc upload failure" do
      before do
        expect(mock_doc_uploader).to receive(:upload_documents_to_claim_evidence)
          .with(correspondence, current_user, parent_task).and_return(false)
      end

      it "fails and does not complete the parent task" do
        result = described.process_intake(intake_params, current_user)

        expect(result).to eq(false)
        expect(parent_task.reload.status).not_to eq("completed")
      end
    end
  end

  describe "#update_correspondence" do 
    context "when Correspondence is found" do
      it "executes update_correspondence successfully" do
        expect_any_instance_of(described_class).to receive(:create_correspondence_relations).with(intake_params, correspondence.id, true)
        expect_any_instance_of(described_class).to receive(:link_appeals_to_correspondence).with(intake_params, correspondence.id)
        expect_any_instance_of(described_class).to receive(:unlink_appeals_to_correspondence).with(intake_params, correspondence)
        expect_any_instance_of(described_class).to receive(:remove_correspondence_relations).with(intake_params, correspondence)
        result = subject.update_correspondence(intake_params)
        expect(result).to be true
      end
    end
  end
end
