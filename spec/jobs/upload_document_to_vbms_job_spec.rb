# frozen_string_literal: true

require "rails_helper"

describe UploadDocumentToVbmsJob do
  describe ".perform" do
    it "calls #call on UploadDocumentToVbms instance" do
      file = "foo"
      document = VbmsUploadedDocument.new(appeal_id: "123", document_type: "bar")

      service = instance_double(UploadDocumentToVbms)
      expect(UploadDocumentToVbms).to receive(:new).with(document: document, file: file).and_return(service)
      expect(service).to receive(:call)

      UploadDocumentToVbmsJob.perform_now(document: document, file: file)
    end
  end
end
