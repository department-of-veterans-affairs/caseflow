# frozen_string_literal: true

describe UploadDocumentToVbmsJob, :postgres do
  describe ".perform" do
    it "calls #call on UploadDocumentToVbms instance" do
      document = create(:vbms_uploaded_document)

      service = instance_double(UploadDocumentToVbms)
      expect(UploadDocumentToVbms).to receive(:new).with(document: document).and_return(service)
      expect(service).to receive(:call)

      UploadDocumentToVbmsJob.perform_now(document_id: document.id)
    end
  end
end
