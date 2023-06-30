# frozen_string_literal: true

describe LegacyAppealDispatch, :all_dbs do
  include ActiveJob::TestHelper

  describe "#call" do
    let(:user) { User.authenticate! }
    let(:legacy_appeal) do
      create(:legacy_appeal,
             :with_veteran,
             vacols_case: create(:case, :aod, :type_cavc_remand, bfregoff: "RO13",
                                                                 folder: create(:folder, tinum: "13 11-265")))
    end
    let(:root_task) { create(:root_task, appeal: legacy_appeal) }
    let(:params) do
      { appeal_id: legacy_appeal.id,
        citation_number: "A18123456",
        decision_date: Time.zone.today,
        redacted_document_location: "some/filepath",
        file: "some file" }
    end
    let(:mail_package) do
      { distributions: [build(:mail_request).call.to_json],
        copies: 1,
        created_by_id: user.id }
    end

    before do
      Seeds::NotificationEvents.new.seed!
      BvaDispatch.singleton.add_user(user)
      BvaDispatchTask.create_from_root_task(root_task)
    end

    subject do
      perform_enqueued_jobs do
        LegacyAppealDispatch.new(appeal: legacy_appeal, params: params, mail_package: mail_package).call
      end
    end

    context "valid parameters" do
      it "successfully outcodes dispatch" do
        expect(subject).to be_success
      end
    end

    context "invalid citation number" do
      it "returns an object with validation errors" do
        params[:citation_number] = "123"
        expect(subject).to_not be_success
        expect(subject.errors[0]).to eq "Citation number is invalid"
      end
    end

    context "citation number already exists" do
      it "returns an object with validation errors" do
        allow_any_instance_of(LegacyAppealDispatch).to receive(:unique_citation_number?).and_return(false)
        expect(subject).to_not be_success
        expect(subject.errors[0]).to eq "Citation number already exists"
      end
    end

    context "missing required parameters" do
      it "returns an object with validation errors" do
        params[:decision_date] = nil
        params[:redacted_document_location] = nil
        params[:file] = nil

        error_message = "Decision date can't be blank, Redacted document " \
                        "location can't be blank, File can't be blank"

        expect(subject).to_not be_success
        expect(subject.errors[0]).to eq error_message
      end
    end

    context "dispatch is associated with a mail request" do
      it "calls #perform_later on MailRequestJob" do
        expect(MailRequestJob).to receive(:perform_later) do |doc, pkg|
          expect(doc).to be_a DecisionDocument
          expect(doc.appeal_type).to eq "LegacyAppeal"
          expect(doc.appeal_id).to eq params[:appeal_id]
          expect(doc.citation_number).to eq params[:citation_number]
          expect(doc.redacted_document_location).to eq params[:redacted_document_location]

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
