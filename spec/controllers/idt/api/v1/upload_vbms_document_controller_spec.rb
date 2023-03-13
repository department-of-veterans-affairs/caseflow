# frozen_string_literal: true

RSpec.describe Idt::Api::V1::UploadVbmsDocumentController, :all_dbs, type: :controller do
  describe "POST /idt/api/v1/appeals/:appeal_id/upload_document" do
    let(:user) { create(:user) }
    let(:appeal) { create(:appeal) }
    let(:veteran) { appeal.veteran }
    let(:file_number) { appeal.veteran.file_number }
    let(:valid_document_type) { "BVA Decision" }
    let(:params) do
      { appeal_id: appeal.external_id,
        file: "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW",
        document_type: valid_document_type }
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

      context "all parameters are valid" do
        let(:uploaded_document) { instance_double(VbmsUploadedDocument, id: 1) }
        let(:document_params) do
          {
            appeal_id: appeal.id,
            appeal_type: appeal.class.name,
            veteran_file_number: file_number,
            document_type: params[:document_type],
            file: params[:file],
            document_name: nil,
            document_subject: nil
          }
        end

        shared_examples "success_with_valid_parameters" do
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
    end
  end
end
