# frozen_string_literal: true

describe AmaAppealDispatch, :postgres do
  include ActiveJob::TestHelper

  let(:user) { User.authenticate! }
  let(:appeal) { create(:appeal, :advanced_on_docket_due_to_age) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:poa_participant_id) { "600153863" }
  let(:bgs_poa) { instance_double(BgsPowerOfAttorney) }
  let(:params) do
    { citation_number: "A18123456",
      decision_date: Time.zone.now,
      redacted_document_location: "C://Windows/User/BLOBLAW/Documents/Decision.docx",
      file: "12345678" }
  end
  let(:mail_package) do
    { distributions: [build(:mail_request).call.to_json],
      copies: 1,
      created_by_id: user.id }
  end

  before do
    BvaDispatch.singleton.add_user(user)
    BvaDispatchTask.create_from_root_task(root_task)
    allow(BgsPowerOfAttorney).to receive(:find_or_create_by_file_number)
      .with(appeal.veteran_file_number).and_return(bgs_poa)
    allow(bgs_poa).to receive(:participant_id).and_return(poa_participant_id)
  end

  before(:all) { Seeds::NotificationEvents.new.seed! }

  subject do
    perform_enqueued_jobs do
      AmaAppealDispatch.new(appeal: appeal, params: params, user: user, mail_package: mail_package).call
    end
  end

  describe "#call" do
    it "stores current POA participant ID in the Appeals table" do
      subject
      expect(appeal.poa_participant_id).to eq poa_participant_id
    end

    context "document is associated with a mail request" do
      it "calls #perform_later on MailRequestJob" do
        expect(MailRequestJob).to receive(:perform_later) do |doc, pkg|
          expect(doc).to be_a DecisionDocument
          expect(doc.appeal_type).to eq "Appeal"
          expect(doc.appeal_id).to eq appeal.id
          expect(doc.redacted_document_location).to eq params[:redacted_document_location]
          expect(doc.citation_number).to eq params[:citation_number]

          expect(pkg).to eq mail_package
        end

        subject
      end
    end

    context "document is not associated with a mail request" do
      let(:mail_package) { nil }
      it "does not call #perform_later on MailRequestJob" do
        expect(MailRequestJob).to_not receive(:perform_later)
        subject
      end
    end

    context "document is not successfully processed" do
      it "does not call #perform_later on MailRequestJob" do
        allow(ProcessDecisionDocumentJob).to receive(:perform_later).and_raise(StandardError)
        expect(MailRequestJob).to_not receive(:perform_later)
        expect { subject }.to raise_error(StandardError)
      end
    end
  end
end
