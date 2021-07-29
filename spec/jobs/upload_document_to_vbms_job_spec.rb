# frozen_string_literal: true

describe UploadDocumentToVbmsJob, :postgres do
  describe ".perform" do
    let(:document) { create(:vbms_uploaded_document) }
    let(:service) { instance_double(UploadDocumentToVbms) }

    subject { UploadDocumentToVbmsJob.perform_now(document_id: document.id) }

    it "calls #call on UploadDocumentToVbms instance" do
      expect(UploadDocumentToVbms).to receive(:new).with(document: document).and_return(service)
      expect(Raven).to receive(:extra_context)
      expect(service).to receive(:call)
      subject
    end
  end
end
