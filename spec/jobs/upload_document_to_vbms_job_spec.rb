require "rails_helper"

describe UploadDocumentToVbmsJob do
  describe ".perform" do
    it "calls #process! on document" do
      document = VbmsUploadedDocument.new(appeal_id: "123", file: "foo", document_type: "bar")

      service = instance_double(UploadDocumentToVbms)
      expect(UploadDocumentToVbms).to receive(:new).with(document).and_return(service)
      expect(service).to receive(:call)

      UploadDocumentToVbmsJob.perform_now(document)
    end
  end
end
