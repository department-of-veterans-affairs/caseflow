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
end
