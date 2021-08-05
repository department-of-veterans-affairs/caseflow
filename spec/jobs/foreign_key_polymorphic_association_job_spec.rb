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

  context "_id is nil regardless of existence of associated record" do
    before do
      sil.update_attribute(:appeal_id, nil)
      sil.update_attribute(:appeal_type, nil)
      appeal.destroy! if [true, false].sample
    end
    it "does not send alert" do
      expect(Appeal.count).to eq(0).or eq(1)
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
    before do
      sil.update_attribute(:appeal_id, nil)
      appeal.destroy! if [true, false].sample
    end
    it "sends alert" do
      expect(Appeal.count).to eq(0).or eq(1)
      expect(sil.appeal_type).not_to eq nil

      subject

      message = "Found SpecialIssueList record with nil appeal_id but non-nil appeal_type: [#{sil.id}]"
      expect(slack_service).to have_received(:send_notification).with(message).once
    end
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
    end

    context "check for N+1 query problem" do
      # TODO: use SqlTracker
      it "sends alert" do
        expect(Appeal.count).to eq 0

        ActiveRecord::Base.logger = Logger.new(STDOUT)
        # ActiveRecord::Base.logger.level = :info
        subject

        message = "Found SpecialIssueList orphaned record: [#{sil.id}]"
        expect(slack_service).to have_received(:send_notification).with(message).once
      end
    end

    context "records for multiple classes where _id exists but the associated record doesn't" do
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

  context "when checking Claimant.participant_id foreign key" do
    let(:claimant) { appeal.claimant }
    context "associated Person exists" do
      it "does not send alert" do
        expect(claimant.reload_person).not_to eq nil
        expect(Person.find_by_participant_id(claimant.participant_id)).not_to eq nil
        subject
        expect(slack_service).not_to have_received(:send_notification)
      end
    end
    context "associated Person does not exist" do
      before do
        claimant.person.destroy!
      end
      it "sends alert" do
        expect(claimant.reload_person).to eq nil
        expect(Person.find_by_participant_id(claimant.participant_id)).to eq nil
        subject

        message = "Found Claimant orphaned record: [#{claimant.id}]"
        expect(slack_service).to have_received(:send_notification).with(message).once
      end
    end
  end
end
