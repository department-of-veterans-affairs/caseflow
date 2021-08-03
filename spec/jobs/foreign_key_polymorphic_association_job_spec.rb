# frozen_string_literal: true

describe ForeignKeyPolymorphicAssociationJob, :postgres do
  subject { described_class.perform_now }

  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  before do
    allow(SlackService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:send_notification) { true }
  end

  let(:appeal) { create(:appeal) }
  let!(:sil) { SpecialIssueList.create(appeal: appeal) }
  # let(:task) { create(:distribution_task) }

  context "_id is nil" do
    before do
      sil.update_column(:appeal_id, nil)
      appeal.destroy!
    end
    it "does not send alert" do
      expect(Appeal.count).to eq 0
      subject
      expect(slack_service).not_to have_received(:send_notification)
    end
  end

  context "_id is non-nil and associated record exists" do
    it "does not send alert" do
      subject
      expect(slack_service).not_to have_received(:send_notification)
    end
  end

  context "_id is nil but _type is non-nil" do
  end

  # This is the main objective of the job
  context "_id is non-nil but the associated record doesn't exist" do
    before do
      appeal.destroy!
    end
    it "sends alert" do
      expect(Appeal.count).to eq 0

      subject

      message = "Found SpecialIssueList orphaned record: [#{sil.id}]"
      expect(slack_service).to have_received(:send_notification).with(message).once
      # binding.pry
    end

    context "multiple classes where _id exists but the associated record doesn't" do
      let(:document_params) do
        {
          appeal_id: appeal.id,
          appeal_type: appeal.class.name,
          document_type: "BVA Decision",
          file: ""
        }
      end
      let!(:vbms_doc) { VbmsUploadedDocument.create(document_params) }

      before do
        appeal.destroy!
      end
      it "sends multiple alerts" do
        expect(Appeal.count).to eq 0

        subject

        message = /Found .* orphaned record/
        expect(slack_service).to have_received(:send_notification).with(message).twice
      end
    end
  end
end
