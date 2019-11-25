# frozen_string_literal: true

describe DocumentFetcher, :postgres do
  let(:appeal) { Generators::LegacyAppeal.build }
  let(:document_service) { DocumentFetcher.new(appeal: appeal, use_efolder: true) }
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
  let(:doc_struct) do
    {
      documents: documents,
      manifest_vbms_fetched_at: service_manifest_vbms_fetched_at.utc.strftime(efolder_fetched_at_format),
      manifest_vva_fetched_at: service_manifest_vva_fetched_at.utc.strftime(efolder_fetched_at_format)
    }
  end

  let(:user) { create(:user) }

  before do
    expect(EFolderService).to receive(:fetch_documents_for).and_return(doc_struct).once
  end

  context "#documents" do
    subject { document_service.documents }

    it "returns a list of documents" do
      expect(subject.count).to eq(2)
      expect(subject.first.type).to eq(documents.first.type)
      expect(subject.second.type).to eq(documents.second.type)
    end

    context "when called multiple times" do
      it "EFolderService is only called once" do
        document_service.documents
        document_service.documents
      end
    end
  end

  context "#number_of_documents" do
    subject { document_service.number_of_documents }

    it "returns the number of documents" do
      expect(subject).to eq(2)
    end
  end

  context "#manifest_vbms_fetched_at" do
    subject { document_service.manifest_vbms_fetched_at }

    it "returns the correct timestamp" do
      expect(subject).to eq(service_manifest_vbms_fetched_at.strftime(fetched_at_format))
    end
  end

  context "#manifest_vva_fetched_at" do
    subject { document_service.manifest_vva_fetched_at }

    it "returns the correct timestamp" do
      expect(subject).to eq(service_manifest_vva_fetched_at.strftime(fetched_at_format))
    end
  end

  context "#find_or_create_documents!" do
    let(:series_id) { "TEST_SERIES_ID" }

    let(:documents) do
      [Generators::Document.build(type: "NOD", series_id: series_id), Generators::Document.build(type: "SOC")]
    end

    context "when there is no existing document" do
      it "saves retrieved documents" do
        returned_documents = document_service.find_or_create_documents!
        expect(returned_documents.map(&:type)).to eq(documents.map(&:type))

        expect(Document.count).to eq(documents.count)
        expect(Document.first.type).to eq(documents[0].type)
        expect(Document.first.received_at).to eq(documents[0].received_at)
      end
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

        returned_documents = document_service.find_or_create_documents!
        expect(returned_documents.first.reload.annotations.count).to eq(0)
      end
    end

    context "when there are documents with same series_id" do
      let!(:saved_documents) do
        [
          Generators::Document.create(type: "Form 9", series_id: series_id, category_procedural: true),
          Generators::Document.create(type: "NOD", series_id: series_id, category_medical: true)
        ]
      end

      it "adds new retrieved documents" do
        expect(Document.count).to eq(2)
        expect(Document.first.type).to eq(saved_documents[0].type)

        returned_documents = document_service.find_or_create_documents!
        expect(returned_documents.map(&:type)).to eq(documents.map(&:type))

        expect(Document.count).to eq(4)
        expect(Document.first.type).to eq("Form 9")
        expect(Document.second.type).to eq("NOD")
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

        it "copies metdata to new document" do
          expect(Annotation.count).to eq(2)
          expect(Annotation.second.comment).to eq(comment)
          expect(DocumentsTag.count).to eq(2)

          document_service.find_or_create_documents!

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
            document_service.find_or_create_documents!

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
        it "updates existing document" do
          expect(Document.count).to eq(1)
          expect(Document.first.type).to eq(saved_documents.type)

          returned_documents = document_service.find_or_create_documents!
          expect(returned_documents.map(&:type)).to eq(documents.map(&:type))

          expect(Document.count).to eq(2)
          expect(Document.first.type).to eq("NOD")
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

      it "adds series_id" do
        expect(Document.count).to eq(1)
        expect(Document.first.type).to eq(saved_document.type)
        expect(Document.first.series_id).to eq(nil)

        returned_documents = document_service.find_or_create_documents!
        expect(returned_documents.map(&:type)).to eq(documents.map(&:type))

        # Adds series id to existing document
        expect(Document.first.series_id).to eq(series_id)
        expect(Document.count).to eq(3)
      end
    end
  end
end
