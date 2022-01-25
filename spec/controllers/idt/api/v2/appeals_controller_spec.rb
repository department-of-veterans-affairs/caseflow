# frozen_string_literal: true

RSpec.describe Idt::Api::V2::AppealsController, :all_dbs, type: :controller do
  describe "GET appeals" do
    let(:ssn) { Generators::Random.unique_ssn }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, :aod, :type_cavc_remand, bfregoff: "RO13", folder: create(:folder, tinum: "13 11-265"))) }
    let(:options) { { format: :json } }
    let(:veteran_id) { appeal.sanitized_vbms_id }
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }
    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    it_behaves_like "IDT access verification", :get, :details

    context "when request header contains valid token" do
      context "and user is a judge" do
        let(:role) { :judge_role }
        let!(:veteran) { create(:veteran, file_number: veteran_id) }

        before do
          create(:staff, role, sdomainid: user.css_id)
          request.headers["TOKEN"] = token
        end

        context "and has access to the file" do
          let!(:veteran) { create(:veteran) }
          let(:appeal) do
            create(:appeal,
                   veteran_file_number: veteran.file_number,
                   claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          end

          it "responds with appeals and claim reviews by veteran id" do
            create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)

            request.headers["HTTP_CASE_SEARCH"] = appeal.veteran_file_number
            get :details, params: options
            response_body = JSON.parse(response.body)

            expect(response_body["appeals"].size).to eq 1
            expect(response_body["claim_reviews"].size).to eq 1
          end

          it "can find by docket number" do
            request.headers["HTTP_CASE_SEARCH"] = appeal.docket_number
            get :details, params: options
            response_body = JSON.parse(response.body)
            expect(response_body["appeals"].size).to eq 1
          end
        end

        context "when request header contains Veteran ID with no associated appeals" do
          it "returns valid response with empty appeals array" do
            appeal = create(:appeal, claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
            create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)
            veteran_without_associated_appeals = create(:veteran)
            request.headers["HTTP_CASE_SEARCH"] = veteran_without_associated_appeals.file_number

            get :details, params: options
            response_body = JSON.parse(response.body)

            expect(response.status).to eq 200
            expect(response_body["appeals"].size).to eq 0
            expect(response_body["claim_reviews"].size).to eq 0
          end
        end
      end
      context "and user is a attorney" do
        let(:role) { :attorney_role }
        let!(:veteran) { create(:veteran, file_number: veteran_id) }

        before do
          create(:staff, role, sdomainid: user.css_id)
          request.headers["TOKEN"] = token
        end

        context "and has access to the file" do
          let!(:veteran) { create(:veteran) }
          let(:appeal) do
            create(:appeal,
                   veteran_file_number: veteran.file_number,
                   claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          end

          it "responds with appeals and claim reviews by veteran id" do
            create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)

            request.headers["HTTP_CASE_SEARCH"] = appeal.veteran_file_number
            get :details, params: options
            response_body = JSON.parse(response.body)

            expect(response_body["appeals"].size).to eq 1
            expect(response_body["claim_reviews"].size).to eq 1
          end

          it "can find by docket number" do
            request.headers["HTTP_CASE_SEARCH"] = appeal.docket_number
            get :details, params: options
            response_body = JSON.parse(response.body)
            expect(response_body["appeals"].size).to eq 1
          end
        end

        context "when request header contains Veteran ID with no associated appeals" do
          it "returns valid response with empty appeals array" do
            appeal = create(:appeal, claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
            create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)
            veteran_without_associated_appeals = create(:veteran)
            request.headers["HTTP_CASE_SEARCH"] = veteran_without_associated_appeals.file_number

            get :details, params: options
            response_body = JSON.parse(response.body)

            expect(response.status).to eq 200
            expect(response_body["appeals"].size).to eq 0
            expect(response_body["claim_reviews"].size).to eq 0
          end
        end
      end
      context "and user is a dispatch" do
        let(:role) { :dispatch_role }
        let!(:veteran) { create(:veteran, file_number: veteran_id) }

        before do
          create(:staff, role, sdomainid: user.css_id)
          request.headers["TOKEN"] = token
        end

        context "and has access to the file" do
          let!(:veteran) { create(:veteran) }
          let(:appeal) do
            create(:appeal,
                   veteran_file_number: veteran.file_number,
                   claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          end

          it "responds with appeals and claim reviews by veteran id" do
            create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)

            request.headers["HTTP_CASE_SEARCH"] = appeal.veteran_file_number
            get :details, params: options
            response_body = JSON.parse(response.body)

            expect(response_body["appeals"].size).to eq 1
            expect(response_body["claim_reviews"].size).to eq 1
          end

          it "can find by docket number" do
            request.headers["HTTP_CASE_SEARCH"] = appeal.docket_number
            get :details, params: options
            response_body = JSON.parse(response.body)
            expect(response_body["appeals"].size).to eq 1
          end
        end

        context "when request header contains Veteran ID with no associated appeals" do
          it "returns valid response with empty appeals array" do
            appeal = create(:appeal, claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
            create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)
            veteran_without_associated_appeals = create(:veteran)
            request.headers["HTTP_CASE_SEARCH"] = veteran_without_associated_appeals.file_number

            get :details, params: options
            response_body = JSON.parse(response.body)

            expect(response.status).to eq 200
            expect(response_body["appeals"].size).to eq 0
            expect(response_body["claim_reviews"].size).to eq 0
          end
        end
        context "when request header contains Veteran ID with no associated appeals" do
          it "returns valid response with empty appeals array" do
            appeal = create(:appeal, claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
            create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)
            veteran_without_associated_appeals = create(:veteran)
            request.headers["HTTP_CASE_SEARCH"] = veteran_without_associated_appeals.file_number

            get :details, params: options
            response_body = JSON.parse(response.body)

            expect(response.status).to eq 200
            expect(response_body["appeals"].size).to eq 0
            expect(response_body["claim_reviews"].size).to eq 0
          end
        end
      end
    end
  end

  describe "GET appeals/:appeal_id" do
    let(:ssn) { Generators::Random.unique_ssn }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, :aod, :type_cavc_remand, bfregoff: "RO13", folder: create(:folder, tinum: "13 11-265"))) }
    let(:options) { { format: :json } }
    let(:veteran_id) { appeal.sanitized_vbms_id }
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }
    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    it_behaves_like "IDT access verification", :get, :details

    context "when request header contains valid token" do
      context "and user is a judge" do
        let(:role) { :judge_role }
        let!(:veteran) { create(:veteran, file_number: veteran_id) }

        before do
          create(:staff, role, sdomainid: user.css_id)
          request.headers["TOKEN"] = token
        end

        context "and has access to the file" do
          let!(:veteran) { create(:veteran) }
          let(:appeal) do
            create(:appeal,
                   veteran_file_number: veteran.file_number,
                   claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          end

          it "appeal is found" do
            create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)

            get :reader_appeal, params: { appeal_id: appeal.uuid }
            response_body = JSON.parse(response.body)

            expect(response_body["appeal"].size).to eq 1
          end

          it "appeal is not found and get not found message" do
            get :reader_appeal, params: { appeal_id: "1234" }
            response_body = JSON.parse(response.body)
            expect(response_body["message"]).to eq "Record not found"
          end
        end
      end
      context "and user is a attorney" do
        let(:role) { :attorney_role }
        let!(:veteran) { create(:veteran, file_number: veteran_id) }

        before do
          create(:staff, role, sdomainid: user.css_id)
          request.headers["TOKEN"] = token
        end

        context "and has access to the file" do
          let!(:veteran) { create(:veteran) }
          let(:appeal) do
            create(:appeal,
                   veteran_file_number: veteran.file_number,
                   claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          end

          it "appeal is found" do
            create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)

            get :reader_appeal, params: { appeal_id: appeal.uuid }
            response_body = JSON.parse(response.body)

            expect(response_body["appeal"].size).to eq 1
          end

          it "appeal is not found and get not found message" do
            get :reader_appeal, params: { appeal_id: "1234" }
            response_body = JSON.parse(response.body)
            expect(response_body["message"]).to eq "Record not found"
          end
        end
      end
      context "and user is a dispatch" do
        let(:role) { :dispatch_role }
        let!(:veteran) { create(:veteran, file_number: veteran_id) }

        before do
          create(:staff, role, sdomainid: user.css_id)
          request.headers["TOKEN"] = token
        end

        context "and has access to the file" do
          let!(:veteran) { create(:veteran) }
          let(:appeal) do
            create(:appeal,
                   veteran_file_number: veteran.file_number,
                   claimants: [build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")])
          end

          it "appeal is found" do
            create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number)

            get :reader_appeal, params: { appeal_id: appeal.uuid }
            response_body = JSON.parse(response.body)

            expect(response_body["appeal"].size).to eq 1
          end

          it "appeal is not found and get not found message" do
            get :reader_appeal, params: { appeal_id: "1234" }
            response_body = JSON.parse(response.body)
            expect(response_body["message"]).to eq "Record not found"
          end
        end
      end
    end
  end
end
