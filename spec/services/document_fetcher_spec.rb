# frozen_string_literal: true

describe DocumentFetcher, :postgres do
  let(:appeal) { Generators::LegacyAppeal.build }
  let(:document_fetcher) { DocumentFetcher.new(appeal: appeal, use_efolder: true) }
  let(:series_id) { "TEST_SERIES_ID" }

  let!(:documents) do
    [
      create(:document),
      create(:document)
    ]
  end

  let(:service_manifest_vbms_fetched_at) { Time.zone.local(1989, "nov", 23, 8, 2, 55) }
  let(:service_manifest_vva_fetched_at) { Time.zone.local(1989, "dec", 13, 20, 15, 1) }

  let(:fetched_at_format) { "%D %l:%M%P %Z %z" }
  let!(:efolder_fetched_at_format) { "%FT%T.%LZ" }
  let(:fetched_doc_struct) do
    {
      # create duplicate documents so as not to modify the original documents used in expect statements
      documents: documents.map(&:dup),
      manifest_vbms_fetched_at: service_manifest_vbms_fetched_at.utc.strftime(efolder_fetched_at_format),
      manifest_vva_fetched_at: service_manifest_vva_fetched_at.utc.strftime(efolder_fetched_at_format)
    }
  end

  let(:user) { create(:user) }

  before do
    expect(EFolderService).to receive(:fetch_documents_for).and_return(fetched_doc_struct).once
  end

  context "#documents" do
    subject { document_fetcher.documents }

    it "returns a list of documents" do
      expect(subject.count).to eq(2)
      expect(subject.first.type).to eq(documents.first.type)
      expect(subject.second.type).to eq(documents.second.type)
    end

    context "when called multiple times" do
      it "EFolderService is only called once" do
        document_fetcher.documents
        document_fetcher.documents
      end
    end
  end

  context "#number_of_documents" do
    subject { document_fetcher.number_of_documents }

    it "returns the number of documents" do
      expect(subject).to eq(2)
    end
  end

  context "#manifest_vbms_fetched_at" do
    subject { document_fetcher.manifest_vbms_fetched_at }

    it "returns the correct timestamp" do
      expect(subject).to eq(service_manifest_vbms_fetched_at.strftime(fetched_at_format))
    end
  end

  context "#manifest_vva_fetched_at" do
    subject { document_fetcher.manifest_vva_fetched_at }

    it "returns the correct timestamp" do
      expect(subject).to eq(service_manifest_vva_fetched_at.strftime(fetched_at_format))
    end
  end

  # Ignore these attributes when comparing document_fetcher.returned_documents with document_service.documents
  IGNORED_ATTRIBUTES = %w[id created_at updated_at file_number previous_document_version_id].freeze

  # These attributes are not saved in the database and must be compared explicitly
  NONDB_ATTRIBUTES = [:efolder_id, :alt_types, :filename].freeze

  context "#find_or_create_documents!" do
    # documents returned by document_fetcher
    let(:documents) do
      [
        Generators::Document.build(id: 201, type: "NOD", series_id: series_id),
        Generators::Document.build(id: 202, type: "SOC")
      ]
    end

    shared_examples "has non-database attributes" do |skip_attribs = []|
      it "sets non-database attributes" do
        returned_documents = document_fetcher.find_or_create_documents!

        returned_docs_by_vbms_id = returned_documents.index_by(&:vbms_document_id)
        documents.each do |doc|
          doc.attributes.each do |key, value|
            next if IGNORED_ATTRIBUTES.include?(key) || skip_attribs.include?(key)

            expect(returned_docs_by_vbms_id[doc.vbms_document_id][key]).to eq(value)
          end

          # These non-database attributes are not included in doc.attributes, so check them explicitly
          NONDB_ATTRIBUTES.each do |attrib|
            expect(doc.send(attrib)).not_to be_nil
            expect(returned_docs_by_vbms_id[doc.vbms_document_id].send(attrib)).to eq(doc.send(attrib))
          end
        end
      end
    end

    context "when there is no existing document" do
      it "saves retrieved documents" do
        returned_documents = document_fetcher.find_or_create_documents!
        expect(returned_documents.map(&:type)).to match_array(documents.map(&:type))

        expect(Document.count).to eq(documents.count)
        expect(Document.first.type).to eq(documents[0].type)
        expect(Document.first.received_at).to eq(documents[0].received_at)
      end

      include_examples "has non-database attributes"
    end

    context "when the series id is nil" do
      let(:series_id) { nil }
      let!(:saved_documents) do
        [
          Generators::Document.create(type: "Form 9", series_id: series_id, category_procedural: true),
          Generators::Document.create(type: "NOD", series_id: series_id, category_medical: true)
        ]
      end
      let(:older_comment) { "OLD_TEST_COMMENT" }
      let(:comment) { "TEST_COMMENT" }
      let!(:existing_annotations) do
        [
          Generators::Annotation.create(
            comment: older_comment,
            x: 1,
            y: 2,
            document_id: saved_documents[0].id
          ),
          Generators::Annotation.create(
            comment: comment,
            x: 1,
            y: 2,
            document_id: saved_documents[1].id
          )
        ]
      end

      it "doesn't copy metadata" do
        expect(Document.count).to eq(2)
        expect(Document.first.type).to eq(saved_documents[0].type)

        returned_documents = document_fetcher.find_or_create_documents!
        expect(returned_documents.count).to eq(2)
        expect(returned_documents.first.reload.annotations.count).to eq(0)
        expect(returned_documents.second.reload.annotations.count).to eq(0)
      end

      include_examples "has non-database attributes"
    end

    context "when there are documents with same series_id" do
      let!(:saved_documents) do
        [
          Generators::Document.create(type: "Form 9", series_id: series_id, category_procedural: true),
          Generators::Document.create(type: "NOD", series_id: series_id, category_medical: true)
        ]
      end

      include_examples "has non-database attributes", ["category_medical"]

      it "adds new retrieved documents" do
        expect(Document.count).to eq(2)
        expect(Document.first.type).to eq(saved_documents.first.type)
        expect(Document.second.type).to eq(saved_documents.second.type)

        returned_documents = document_fetcher.find_or_create_documents!
        expect(returned_documents.count).to eq(2)
        expect(Document.count).to eq(4)

        expect(returned_documents.map(&:type)).to match_array(documents.map(&:type))

        expect(Document.first.type).to eq(saved_documents.first.type)
        expect(Document.second.type).to eq(saved_documents.second.type)
        expect([Document.third.type, Document.fourth.type]).to match_array(returned_documents.map(&:type))

        # According to DocumentFetcher.create_new_document!,
        # since returned_documents.first has the same series_id as the 2 saved_documents,
        # it should have the same categories as the latest saved_document with the same series_id.
        expect(Document.third.series_id).to eq(series_id)
        expect(Document.third.series_id).to eq(saved_documents.first.series_id)
        expect(Document.third.series_id).to eq(saved_documents.second.series_id)
        expect(Document.third.category_medical).to eq(saved_documents.second.category_medical)
      end

      context "when existing document has comments, tags, and categories" do
        let(:older_comment) { "OLD_TEST_COMMENT" }
        let(:comment) { "TEST_COMMENT" }
        let(:tag) { "TEST_TAG" }
        let!(:existing_annotations) do
          [
            Generators::Annotation.create(
              comment: older_comment,
              x: 1,
              y: 2,
              document_id: saved_documents[0].id
            ),
            Generators::Annotation.create(
              comment: comment,
              x: 1,
              y: 2,
              document_id: saved_documents[1].id
            )
          ]
        end
        let!(:document_tag) do
          [
            DocumentsTag.create(
              tag_id: Generators::Tag.create(text: "NOT USED TAG").id,
              document_id: saved_documents[0].id
            ),
            DocumentsTag.create(
              tag_id: Generators::Tag.create(text: tag).id,
              document_id: saved_documents[1].id
            )
          ]
        end

        include_examples "has non-database attributes", ["category_medical"]

        it "copies metdata to new document" do
          expect(Annotation.count).to eq(2)
          expect(Annotation.second.comment).to eq(comment)
          expect(DocumentsTag.count).to eq(2)

          document_fetcher.find_or_create_documents!

          expect(Annotation.count).to eq(3)
          expect(Document.second.annotations.first.comment).to eq(comment)
          expect(Document.third.annotations.first.comment).to eq(comment)

          expect(DocumentsTag.count).to eq(3)
          expect(Document.second.documents_tags.first.tag.text).to eq(tag)
          expect(Document.third.documents_tags.first.tag.text).to eq(tag)

          expect(Document.second.category_medical).to eq(true)
          expect(Document.third.category_medical).to eq(true)
        end

        context "when the API returns two documents with the same series_id" do
          let(:documents) do
            [
              Generators::Document.build(type: "NOD", series_id: series_id),
              Generators::Document.build(type: "SOC"),
              saved_documents[1]
            ]
          end

          it "copies metadata from the most recently saved document not returned by the API" do
            document_fetcher.find_or_create_documents!

            expect(Document.third.annotations.first.comment).to eq(older_comment)
          end
        end
      end

      context "when API returns doc that is already saved" do
        let!(:saved_documents) do
          Generators::Document.create(
            type: "Form 9",
            series_id: series_id,
            vbms_document_id: documents[0].vbms_document_id
          )
        end

        include_examples "has non-database attributes"

        it "updates existing document" do
          expect(Document.count).to eq(1)
          expect(Document.first.type).to eq(saved_documents.type)

          returned_documents = document_fetcher.find_or_create_documents!
          expect(returned_documents.map(&:type)).to match_array(documents.map(&:type))

          expect(Document.count).to eq(2)
          expect(Document.first.type).to eq("NOD")
        end
      end

      context "when API returns many documents" do
        # Increase the size of the array to test scalability; 20000 works but takes a minute or so
        let(:documents) { Array.new(50) { Generators::Document.build }.uniq(&:vbms_document_id) }
        let!(:saved_documents) do
          Array.new(20) do |i|
            # to test that all CREATEs and UPDATEs are each done at most once,
            # have every other document already exists (up to 20 records)
            fetched_document = documents[i * 2]
            Generators::Document.create(
              type: "Form 9",
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
              type: "Form 9",
              series_id: fetched_document.series_id,
              vbms_document_id: fetched_document.vbms_document_id + ".old"
            )
            Generators::Annotation.create(document_id: doc.id, comment: "existing comment", x: rand(100), y: rand(100))
            DocumentsTag.create(document_id: doc.id, tag_id: doc_tag.id)
          end
        end
        it "efficiently creates and updates documents" do
          expect(Document.distinct.pluck(:type)).to eq(["Form 9"])

          # Uncomment the following to see all SQL queries made
          # ActiveRecord::Base.logger = Logger.new(STDOUT)
          query_data = SqlTracker.track do
            document_fetcher.find_or_create_documents!
          end

          # Uncomment the following to see a count of SQL queries
          # pp query_data.values.pluck(:sql, :count)
          doc_insert_queries = query_data.values.select { |o| o[:sql].start_with?("INSERT INTO \"documents\"") }
          expect(doc_insert_queries.pluck(:count).max).to eq 1

          # When metadata exists for a previous version of a document, queries remain inefficient
          annotns_insert_queries = query_data.values.select { |o| o[:sql].start_with?("INSERT INTO \"annotations\"") }
          expect(annotns_insert_queries.pluck(:count).max).to eq older_documents_with_metadata.count

          doctags_insert_queries = query_data.values.select { |o| o[:sql].start_with?("INSERT INTO \"documents_tags") }
          expect(doctags_insert_queries.pluck(:count).max).to eq older_documents_with_metadata.count

          doc_update_queries = query_data.values.select { |o| o[:sql].start_with?("UPDATE \"documents\"") }
          expect(doc_update_queries.pluck(:count).max).to eq older_documents_with_metadata.count
        end

        context "when there are duplicate documents returned from document_service" do
          let(:documents) do
            docs = Array.new(50) { Generators::Document.build }.uniq(&:vbms_document_id)
            # docs.first.dup will already exist in the DB and hence will be UPDATED
            # docs.second.dup does not exist in the DB and hence should be CREATED
            # docs.third.dup will already exist in the DB but since it has different attributes, causes a Sentry alert
            doc_with_diff_attrib = docs.third.dup.tap { |doc| doc.type = "Diff doc" }
            docs + [docs.first.dup, docs.second.dup, doc_with_diff_attrib]
          end
          it "deduplicates, sends warning to Sentry, and does not fail bulk upsert" do
            expect(documents.map(&:vbms_document_id).count).to eq(53)
            expect(documents.map(&:vbms_document_id).uniq.count).to eq(50)
            expect(Document.count).to eq(saved_documents.count + older_documents_with_metadata.count)
            expect(Document.find_by(vbms_document_id: documents.first.vbms_document_id)).not_to be_nil
            expect(Document.find_by(vbms_document_id: documents.second.vbms_document_id)).to be_nil
            expect(Document.find_by(vbms_document_id: documents.third.vbms_document_id)).not_to be_nil

            expected_error_message = "Document records with duplicate vbms_document_id: fetched_documents"
            expect(Raven).to receive(:capture_exception).with(
              DocumentFetcher::DuplicateVbmsDocumentIdError.new(expected_error_message),
              hash_including(extra: hash_including(application: "reader", nonexact_dup_docs_count: 1))
            )

            query_data = SqlTracker.track do
              document_fetcher.find_or_create_documents!
            end

            # pp query_data.values.pluck(:sql, :count)
            doc_insert_queries = query_data.values.select { |o| o[:sql].start_with?("INSERT INTO \"documents\"") }
            expect(doc_insert_queries.pluck(:count).max).to eq 1
            expect(query_data.values.select { |o| o[:sql].start_with?("UPDATE \"documents\"") }.pluck(:count).max)
              .to eq(older_documents_with_metadata.count)
          end
        end
      end
    end

    context "when there is a document with no series_id" do
      let(:vbms_document_id) { "TEST_VBMS_DOCUMENT_ID" }
      let!(:saved_document) do
        Generators::Document.create(
          type: "Form 9",
          vbms_document_id: vbms_document_id,
          series_id: nil,
          file_number: appeal.sanitized_vbms_id
        )
      end

      before do
        expect(VBMSService).to receive(:fetch_document_series_for).with(appeal).and_return(
          [[
            OpenStruct.new(
              vbms_filename: "test_file",
              type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
              document_id: vbms_document_id,
              version_id: vbms_document_id,
              series_id: series_id,
              version: 0,
              mime_type: "application/pdf",
              received_at: rand(100).days.ago,
              downloaded_from: "VBMS"
            ),
            OpenStruct.new(
              vbms_filename: "test_file",
              type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
              document_id: "DIFFERENT_ID",
              version_id: "DIFFERENT_ID",
              series_id: series_id,
              version: 1,
              mime_type: "application/pdf",
              received_at: rand(100).days.ago,
              downloaded_from: "VBMS"
            )
          ]]
        )
      end

      include_examples "has non-database attributes"

      it "adds series_id" do
        expect(Document.count).to eq(1)
        expect(Document.first.type).to eq(saved_document.type)
        expect(Document.first.series_id).to eq(nil)

        returned_documents = document_fetcher.find_or_create_documents!
        expect(returned_documents.map(&:type)).to match_array(documents.map(&:type))

        # Adds series id to existing document
        expect(Document.first.series_id).to eq(series_id)
        expect(Document.count).to eq(3)
      end
    end
  end
end
