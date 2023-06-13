# frozen_string_literal: true

RSpec.describe Idt::Api::V1::UploadVbmsDocumentController, :all_dbs, type: :controller do
  include ActiveJob::TestHelper

  describe "POST /idt/api/v1/appeals/:appeal_id/upload_document" do
    let(:user) { create(:user) }
    let(:appeal) { create(:appeal) }
    let(:veteran) { appeal.veteran }
    let(:file_number) { appeal.veteran.file_number }
    let(:file) { "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW" }
    let(:valid_document_type) { "BVA Decision" }
    let(:params) do
      { appeal_id: appeal.external_id,
        file: file,
        document_type: valid_document_type }
    end

    let(:mail_request_params) do
      { veteran_identifier: veteran.file_number,
        file: file,
        document_type: valid_document_type,
        recipient_info: [
          {
            recipient_type: "person",
            first_name: "Bob",
            last_name: "Smithmetz",
            participant_id: "487470002",
            destination_type: "domesticAddress",
            address_line_1: "1234 Main Street",
            treat_line_2_as_addressee: false,
            treat_line_3_as_addressee: false,
            city: "Orlando",
            state: "FL",
            postal_code: "12345",
            country_code: "US"
          }
        ] }
    end

    let(:invalid_mail_request_params) do
      { veteran_identifier: veteran.file_number,
        file: "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW",
        document_type: valid_document_type,
        recipient_info: [
          {
            recipient_type: "person",
            participant_id: "487470002",
            destination_type: "domesticAddress",
            address_line_1: "1234 Main Street",
            treat_line_2_as_addressee: false,
            treat_line_3_as_addressee: false,
            city: "Orlando",
            state: "FL",
            postal_code: "12345",
            country_code: "US"
          }
        ] }
    end

    let(:params_identifier) do
      { veteran_identifier: veteran.file_number,
        file: "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW",
        document_type: valid_document_type }
    end

    describe "authorization" do
      it_behaves_like "IDT access verification", :post, :create, appeal_id: "123"
    end

    describe "validations" do
      before do
        BvaDispatch.singleton.add_user(user)
        key, t = Idt::Token.generate_one_time_key_and_proposed_token
        Idt::Token.activate_proposed_token(key, user.css_id)
        request.headers["TOKEN"] = t
        create(:staff, :attorney_role, sdomainid: user.css_id)
        allow_any_instance_of(BGSService).to receive(:fetch_file_number_by_ssn) { file_number }
      end

      context "when document_type param is missing" do
        it "throws an error" do
          post :create, params: { appeal_id: appeal.external_id, file: "foo" }
          err_msg = JSON.parse(response.body)["message"]

          expect(err_msg).to eq "Document type is not recognized"
          expect(response.status).to eq(400)
        end
      end

      context "document_type is blank" do
        it "throws an error" do
          post :create, params: { appeal_id: appeal.external_id, document_type: "", file: "foo" }
          err_msg = JSON.parse(response.body)["message"]

          expect(err_msg).to eq "Document type is not recognized"
          expect(response.status).to eq(400)
        end
      end

      context "document_type is present but invalid" do
        it "throws an error" do
          post :create, params: { appeal_id: appeal.external_id, document_type: "foo", file: "foo" }
          err_msg = JSON.parse(response.body)["message"]

          expect(err_msg).to eq "Document type is not recognized"
          expect(response.status).to eq(400)
        end
      end

      context "file param is missing" do
        it "throws an error" do
          post :create, params: { appeal_id: appeal.external_id, document_type: valid_document_type }
          err_msg = JSON.parse(response.body)["message"]

          expect(err_msg).to eq "File can't be blank"
          expect(response.status).to eq(400)
        end
      end

      context "file param is blank" do
        it "throws an error" do
          post :create, params: { appeal_id: appeal.external_id, document_type: valid_document_type, file: "" }
          err_msg = JSON.parse(response.body)["message"]

          expect(err_msg).to eq "File can't be blank"
          expect(response.status).to eq(400)
        end
      end

      context "when appeal id doesn't match in database" do
        it "returns an AppealNotFound error" do
          params["appeal_id"] = appeal.uuid + "123"
          post :create, params: params
          expect(response).to have_attributes(status: 400)
          error_msg = JSON.parse(response.body)["message"]
          expect(error_msg).to include("The appeal was unable to be found.")
        end
      end

      context "when veteran identifier doesn't match in BGS" do
        it "returns a VeteranNotFound error" do
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_return(nil)
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_file_number_by_ssn).and_return(nil)
          post :create, params: params_identifier
          expect(response).to have_attributes(status: 400)
          error_msg = JSON.parse(response.body)["message"]
          expect(error_msg).to include("The veteran was unable to be found.")
        end
      end

      context "UploadDocumentToVbmsJob raises an error" do
        it "throws an error" do
          allow(UploadDocumentToVbmsJob).to receive(:perform_later).and_raise("job error")
          post :create, params: params
          err_msg = JSON.parse(response.body)["message"]

          expect(err_msg).to include "Unexpected error: job error"
          expect(response.status).to eq(500)
        end
      end

      context "when the recipient_info parameters are incomplete" do
        it "queues the upload(given valid veteran info), returns a descriptive error to the IDT user" do
          expect(Raven).to receive(:capture_exception)
          post :create, params: invalid_mail_request_params
          success_message = JSON.parse(response.body)["message"]
          validation_error_msgs = JSON.parse(response.body)["error_messages"]
          error = JSON.parse(response.body)["error"]
          expect(success_message).to eq "Document successfully queued for upload."
          expect(validation_error_msgs).to eq(
            {
              "first_name" => ["can't be blank"],
              "last_name" => ["can't be blank"]
            }
          )
          expect(error).to eq("Incomplete mailing information provided. No mail request was created.")
          expect(response.status).to eq(200)
        end
      end

      context "all parameters are valid" do
        let(:uploaded_document) { instance_double(VbmsUploadedDocument, id: 1) }
        let(:document_params) do
          {
            appeal_id: appeal.id,
            appeal_type: appeal.class.name,
            veteran_file_number: file_number,
            document_type: params[:document_type],
            file: file,
            document_name: nil,
            document_subject: nil
          }
        end

        shared_examples "success_with_valid_parameters" do
          it "creates a new Mail Request object when optional params exist" do
            expect_any_instance_of(MailRequest).to receive(:call)
            post :create, params: mail_request_params
          end

          it "returns a list of vbms_distribution ids alongside a success message" do
            post :create, params: mail_request_params
            success_message = JSON.parse(response.body)["message"]
            success_id = JSON.parse(response.body)["distribution_ids"]
            # expect(VbmsDistribution).to change(:count).by(1)
            expect(success_message).to eq "Document successfully queued for upload."
            expect(success_id).not_to eq([])
            expect(response.status).to eq(200)
          end

          it "returns a successful message and creates a new VbmsUploadedDocument" do
            expect { post :create, params: params }.to change(VbmsUploadedDocument, :count).by(1)

            success_message = JSON.parse(response.body)["message"]

            expect(success_message).to eq "Document successfully queued for upload."
            expect(response.status).to eq(200)
          end

          it "queues the document for upload to VBMS" do
            expect(VbmsUploadedDocument).to receive(:create).with(document_params).and_return(uploaded_document)
            expect(UploadDocumentToVbmsJob).to receive(:perform_later).with(
              document_id: uploaded_document.id,
              initiator_css_id: user.css_id,
              application: anything
            )
            expect(uploaded_document).to receive(:cache_file)

            post :create, params: params
          end
        end

        it_behaves_like "success_with_valid_parameters"

        context "the appeal is a LegacyAppeal" do
          let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
          let(:veteran) { create(:veteran) }

          before do
            allow(appeal).to receive(:veteran) { veteran }
          end

          it_behaves_like "success_with_valid_parameters"
        end
      end

      context "queues async mail request job" do
        let(:recipient_info) { mail_request_params[:recipient_info] }
        let(:mail_request) { MailRequest.new(recipient_info[0]) }
        let(:mail_request_job) { class_double(MailRequestJob) }
        let(:mail_package) do
          { distributions: [mail_request.to_json],
            copies: 1 }
        end
        let(:uploaded_document) { instance_double(VbmsUploadedDocument, id: 1) }
        let(:upload_job_params) do
          { document_id: uploaded_document.id,
            initiator_css_id: user.css_id,
            application: nil,
            mail_package: mail_package }
        end

        context "document is associated with a mail package" do
          it "calls #perform_later on MailRequestJob" do
            post :create, params: mail_request_params, as: :json
            expect(mail_request_job).to receive(:perform_later)
            perform_enqueued_jobs do
              UploadDocumentToVbmsJob.perform_later(upload_job_params)
            end
          end
        end

        context "document is not associated with a mail package" do
          it "does not call #perform_later on MailRequestJob" do
            mail_request_params[:recipient_info] = []
            post :create, params: mail_request_params, as: :json
            expect(mail_request_job).to_not receive(:perform_later)
          end
        end

        context "recipient info is incorrect" do
          it "does not call #perform_later on MailRequestJob" do
            post :create, params: invalid_mail_request_params, as: :json
            expect(mail_request_job).to_not receive(:perform_later)
          end
        end
      end
    end
  end
end
