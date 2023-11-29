SingleCov.covered!
# frozen_string_literal: true

RSpec.describe Idt::Api::V2::AppealsController, :postgres, :all_dbs, type: :controller do
  describe "GET appeals" do
    let(:ssn) { Generators::Random.unique_ssn }
    let(:appeal) do
      create(:legacy_appeal,
             vacols_case: create(:case, :aod, :type_cavc_remand, bfregoff: "RO13",
                                                                 folder: create(:folder, tinum: "13 11-265")))
    end
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
    let(:appeal) do
      create(:legacy_appeal,
             vacols_case: create(:case, :aod, :type_cavc_remand, bfregoff: "RO13",
                                                                 folder: create(:folder, tinum: "13 11-265")))
    end
    let(:options) { { format: :json } }
    let(:veteran_id) { appeal.sanitized_vbms_id }
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }
    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

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
            expect(response_body["message"]).to include "Record not found"
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
            expect(response_body["message"]).to include "Record not found"
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
            expect(response_body["message"]).to include "Record not found"
          end
        end
      end
    end
  end

  describe "GET appeals/:appeals_id/documents" do
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }
    let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: user.css_id) }
    let!(:appeal) { create(:appeal) }
    let(:params) { { format: :json, appeal_id: appeal.uuid } }
    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    before { User.authenticate!(user: user) }
    after { User.unauthenticate! }

    before do
      fetched_doc_struct = {
        # create duplicate documents so as not to modify the original documents used in expect statements
        documents: documents.map(&:dup),
        manifest_vbms_fetched_at: Time.zone.local(1989, "nov", 23, 8, 2, 55).utc.strftime("%FT%T.%LZ"),
        manifest_vva_fetched_at: Time.zone.local(1989, "dec", 13, 20, 15, 1).utc.strftime("%FT%T.%LZ")
      }
      expect(EFolderService).to receive(:fetch_documents_for).and_return(fetched_doc_struct).once
      request.headers["TOKEN"] = token
    end

    context "when API returns many documents" do
      let(:documents) { Array.new(50) { Generators::Document.build }.uniq(&:vbms_document_id) }
      let!(:saved_documents) do
        Array.new(20) do |i|
          # to test that all CREATEs and UPDATEs are each done at most once,
          # have every other document already exists (up to 20 records)
          fetched_document = documents[i * 2]
          Generators::Document.create(
            type: "SOC",
            series_id: fetched_document.series_id,
            vbms_document_id: fetched_document.vbms_document_id
          )
        end
      end
      let(:doc_tag) { Generators::Tag.create(text: "existing tag") }
      let!(:older_documents_with_metadata) do
        Array.new(13) do |i|
          fetched_document = documents[(i * 2) + 1]
          # same series_id but different vbms_document_id indicate different versions of same document
          doc = Generators::Document.create(
            type: "SOC",
            series_id: fetched_document.series_id,
            vbms_document_id: fetched_document.vbms_document_id + ".old",
            category_medical: true
          )
          Generators::Annotation.create(document_id: doc.id, comment: "existing comment", x: rand(100), y: rand(100))
          DocumentsTag.create(document_id: doc.id, tag_id: doc_tag.id)
          doc
        end
      end
      it "efficiently queries and returns correct response" do
        ActiveRecord::Base.logger = Logger.new(STDOUT)
        controller_query_data = SqlTracker.track do
          get :appeal_documents, params: params
        end

        response_body = JSON.parse(response.body)
        response_body_keys = %w[appealDocuments annotations manifestVbmsFetchedAt manifestVvaFetchedAt].freeze
        expect(response_body.keys).to match_array(response_body_keys)
        expect(response_body["manifestVbmsFetchedAt"]).to_not be_nil
        expect(response_body["manifestVvaFetchedAt"]).to_not be_nil
        expect(response_body["appealDocuments"].size).to eq documents.count

        # Check that annotations and tags from older_documents_with_metadata are included in response
        expect(response_body["annotations"].size).to eq older_documents_with_metadata.count
        nonempty_tags = response_body["appealDocuments"].pluck("tags").reject(&:empty?)
        expect(nonempty_tags.count).to eq older_documents_with_metadata.count

        # All annotations have the same comment
        expect(response_body["annotations"].pluck("comment").uniq).to eq ["existing comment"]
        # All tags have the same tag
        expect(nonempty_tags.flatten.pluck("text").uniq).to eq ["existing tag"]
        # older_documents_with_metadata have category_medical==true
        docs_with_metadata = response_body["appealDocuments"].reject { |doc| doc["category_medical"].nil? }
        expect(docs_with_metadata.count).to eq older_documents_with_metadata.count

        # 20 saved_documents are updated and should be returned
        returned_doc_ids = response_body["appealDocuments"].pluck("id")
        expect(returned_doc_ids).to include(*saved_documents.pluck(:id))

        # 30 remaining_returned documents are newly created; 13 new versions of known docs + 17 new docs
        remaining_returned_doc_ids = returned_doc_ids - saved_documents.pluck(:id)
        remaining_returned_docs = Document.where(id: remaining_returned_doc_ids)
        returned_docs_with_prev_version = remaining_returned_docs.where.not(previous_document_version_id: nil)
        expect(returned_docs_with_prev_version.count).to eq 13
        expect(remaining_returned_doc_ids).to_not include(*older_documents_with_metadata.pluck(:id))
        expect(remaining_returned_docs.where(previous_document_version_id: nil).count).to eq 17

        # All returned_docs_with_prev_version have annotations, so check that annotations were copied to new docs
        doc_ids_with_annotations = response_body["annotations"].pluck("document_id")
        expect(doc_ids_with_annotations).to match_array(returned_docs_with_prev_version.pluck(:id))
        expect(doc_ids_with_annotations).to match_array(docs_with_metadata.pluck("id"))

        # Uncomment the following to see a count of SQL queries
        # pp controller_query_data.values.pluck(:sql, :count)
        single_annot_query = "SELECT \"annotations\".* FROM \"annotations\""
        annotation_select_queries = controller_query_data.values.select { |o| o[:sql].start_with?(single_annot_query) }
        expect(annotation_select_queries.pluck(:count).max).to be <= 2

        single_tags_query = "SELECT \"tags\".* FROM \"tags\""
        tag_select_queries = controller_query_data.values.select { |o| o[:sql].start_with?(single_tags_query) }
        expect(tag_select_queries.pluck(:count).max).to be <= 1
      end
    end
  end

  describe "GET appeals/:appeals_id/documents/:document_id" do
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }
    let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: user.css_id) }
    let!(:appeal) { create(:appeal) }
    let(:params) { { format: :json, appeal_id: appeal.uuid } }
    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    before { User.authenticate!(user: user) }
    after { User.unauthenticate! }

    before do
      fetched_doc_struct = {
        # create duplicate documents so as not to modify the original documents used in expect statements
        documents: documents.map(&:dup),
        manifest_vbms_fetched_at: Time.zone.local(1989, "nov", 23, 8, 2, 55).utc.strftime("%FT%T.%LZ"),
        manifest_vva_fetched_at: Time.zone.local(1989, "dec", 13, 20, 15, 1).utc.strftime("%FT%T.%LZ")
      }
      expect(EFolderService).to receive(:fetch_documents_for).and_return(fetched_doc_struct).once
      request.headers["TOKEN"] = token
    end

    context "when API returns one document" do
      let(:documents) { Array.new(50) { Generators::Document.build }.uniq(&:vbms_document_id) }
      let!(:saved_documents) do
        Array.new(20) do |i|
          # to test that all CREATEs and UPDATEs are each done at most once,
          # have every other document already exists (up to 20 records)
          fetched_document = documents[i * 2]
          Generators::Document.create(
            type: "SOC",
            series_id: fetched_document.series_id,
            vbms_document_id: fetched_document.vbms_document_id
          )
        end
      end
      let(:doc_tag) { Generators::Tag.create(text: "existing tag") }
      let!(:older_documents_with_metadata) do
        Array.new(13) do |i|
          fetched_document = documents[(i * 2) + 1]
          # same series_id but different vbms_document_id indicate different versions of same document
          doc = Generators::Document.create(
            type: "SOC",
            series_id: fetched_document.series_id,
            vbms_document_id: fetched_document.vbms_document_id + ".old",
            category_medical: true
          )
          Generators::Annotation.create(document_id: doc.id, comment: "existing comment", x: rand(100), y: rand(100))
          DocumentsTag.create(document_id: doc.id, tag_id: doc_tag.id)
          doc
        end
      end
      it "efficiently returns correct response" do
        get :appeal_documents, params: params
        response_body = JSON.parse(response.body)
        doc_id = response_body["appealDocuments"][0]["id"]
        get :appeals_single_document, params: { appeal_id: appeal.uuid, document_id: doc_id.to_s }
        response_body = JSON.parse(response.body)
        expect(response.status).to eq 200
        expect(response_body.size).to eq 1
        expect(response_body[0]["id"]).to eq doc_id
      end

      it "downloads a file" do
        get :appeal_documents, params: params
        response_body = JSON.parse(response.body)
        doc_id = response_body["appealDocuments"][0]["id"]
        get :appeals_single_document, params: { appeal_id: appeal.uuid, document_id: doc_id.to_s, download: true }
        expect(response.status).to eq 200
      end
    end
  end

  describe "POST /idt/api/v2/appeals/:appeal_id/outcode", :postgres do
    let(:user) { create(:user) }
    let(:root_task) { create(:root_task) }
    let(:citation_number) { "A18123456" }
    let(:params) do
      { appeal_id: root_task.appeal.external_id,
        citation_number: citation_number,
        decision_date: Date.new(1989, 12, 13).to_s,
        file: "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW",
        redacted_document_location: "C://Windows/User/BLOBLAW/Documents/Decision.docx",
        recipient_info: [] }
    end

    before do
      BvaDispatch.singleton.add_user(user)

      key, t = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      request.headers["TOKEN"] = t
      create(:staff, :attorney_role, sdomainid: user.css_id)
    end

    context "when some params are missing" do
      let(:params) { { appeal_id: root_task.appeal.external_id, citation_number: citation_number } }
      before { BvaDispatchTask.create_from_root_task(root_task) }

      it "should throw an error" do
        post :outcode, params: params
        error_message = "Decision date can't be blank, Redacted document " \
                        "location can't be blank, File can't be blank"

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["message"]).to eq error_message
      end
    end

    context "when citation_number parameter fails validation" do
      let(:citation_number) { "INVALID" }
      before { BvaDispatchTask.create_from_root_task(root_task) }

      it "throws an error" do
        post :outcode, params: params

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["message"]).to eq "Citation number is invalid"
      end
    end

    context "when citation_number already exists on a different appeal" do
      before do
        BvaDispatchTask.create_from_root_task(root_task)
        create(:decision_document, citation_number: citation_number, appeal: create(:appeal))
      end

      it "throws an error" do
        post :outcode, params: params

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["message"]).to eq "Citation number already exists"
      end
    end

    context "when single BvaDispatchTask exists for user and appeal combination" do
      before { BvaDispatchTask.create_from_root_task(root_task) }

      it "should complete the BvaDispatchTask assigned to the User and the task assigned to the BvaDispatch org" do
        post :outcode, params: params
        expect(response.status).to eq(200)

        tasks = BvaDispatchTask.where(appeal: root_task.appeal, assigned_to: user)

        expect(tasks.length).to eq(1)

        task = tasks[0]

        expect(task.status).to eq("completed")
        expect(task.parent.status).to eq("completed")
        expect(S3Service.files["decisions/" + root_task.appeal.external_id + ".pdf"]).to_not eq nil
        expect(DecisionDocument.find_by(appeal_id: root_task.appeal.id)&.submitted_at).to_not be_nil
        expect(JSON.parse(response.body)["message"]).to eq("Successful dispatch!")
      end

      context "when dispatch is associated with a mail request" do
        include ActiveJob::TestHelper

        let(:recipient) do
          { recipient_type: "person",
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
            country_code: "US" }
        end

        before { params[:recipient_info] << recipient }

        it "calls #perform_later on MailRequestJob" do
          expect(MailRequestJob).to receive(:perform_later)

          perform_enqueued_jobs { post :outcode, params: params, as: :json }
        end

        context "recipient info is incorrect" do
          it "returns validation errors and does not call #perform_later on MailRequestJob" do
            recipient[:first_name] = nil
            expect(MailRequestJob).to_not receive(:perform_later)
            perform_enqueued_jobs { post :outcode, params: params, as: :json }
            error_message = JSON.parse(response.body)["errors"]["distribution 1"]
            expect(error_message).to eq("First name can't be blank")
          end
        end

        context "when dispatch is not successfully processed" do
          let(:citation_number) { "INVALID" }
          it "does not call #perform_later on MailRequestJob" do
            perform_enqueued_jobs { expect(MailRequestJob).to_not receive(:perform_later) }
            post :outcode, params: params
          end
        end
      end

      context "when dispatch is not associated with a mail request" do
        it "does not call #perform_later on MailRequestJob" do
          params[:recipient_info] = []
          expect(MailRequestJob).to_not receive(:perform_later)
          post :outcode, params: params
        end
      end
    end

    context "when multiple BvaDispatchTasks exists for user and appeal combination" do
      let(:task_count) { 2 }

      before do
        task_count.times do
          org_task = BvaDispatchTask.create_from_root_task(root_task)
          # Set status of org-level task to completed to avoid getting caught by Task.verify_org_task_unique.
          org_task.update!(status: Constants.TASK_STATUSES.completed)
        end
      end

      it "throws an error" do
        post :outcode, params: params

        expect(response.status).to eq(400)
        response_detail = JSON.parse(response.body)["errors"][0]["detail"]
        expect(response_detail).to eq("Expected 1 BvaDispatchTask received #{task_count} tasks for appeal "\
                                      "#{root_task.appeal.id}, user #{user.id}")
      end
    end

    context "when no BvaDispatchTasks exists for user and appeal combination" do
      let(:task_count) { 0 }

      it "throws an error" do
        post :outcode, params: params

        expect(response.status).to eq(400)
        response_detail = JSON.parse(response.body)["errors"][0]["detail"]
        expect(response_detail).to eq("Expected 1 BvaDispatchTask received #{task_count} tasks for appeal "\
                                      "#{root_task.appeal.id}, user #{user.id}")
      end
    end

    context "when appeal has already been outcoded" do
      before do
        allow(controller).to receive(:sentry_reporting_is_live?) { true }
        allow(Raven).to receive(:user_context) do |args|
          @raven_user = args
        end
      end

      it "throws an error" do
        BvaDispatchTask.create_from_root_task(root_task)
        post :outcode, params: params
        post :outcode, params: params.merge(citation_number: "A12131989")

        expect(response.status).to eq(400)

        response_detail = JSON.parse(response.body)["errors"][0]["detail"]
        task = BvaDispatchTask.find_by(appeal: root_task.appeal, assigned_to: user)
        error_message = "Appeal #{root_task.appeal.id}, task ID #{task.id} has already been outcoded. " \
                        "Cannot outcode the same appeal and task combination more than once"

        expect(response_detail).to eq error_message
        expect(@raven_user[:css_id]).to eq(user.css_id)
      end
    end

    context "when veteran file number doesn't match BGS file number" do
      before do
        allow_any_instance_of(BGSService).to receive(:fetch_file_number_by_ssn) { "123123123" }
      end
      it "throws an error" do
        BvaDispatchTask.create_from_root_task(root_task)
        post :outcode, params: params

        expect(response.status).to eq(500)
        response_detail = JSON.parse(response.body)["errors"][0]["detail"]
        response_title = JSON.parse(response.body)["errors"][0]["title"]

        error_message = "The veteran file number does not match the file number in VBMS"
        error_title = "VBMS::FilenumberDoesNotExist"

        expect(response_detail).to eq error_message
        expect(response_title).to eq error_title
      end
    end
  end
end
