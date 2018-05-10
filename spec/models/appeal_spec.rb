describe Appeal do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:appeal) do
    Generators::Appeal.build(
      notification_date: notification_date,
      nod_date: nod_date,
      soc_date: soc_date,
      form9_date: form9_date,
      ssoc_dates: ssoc_dates,
      certification_date: certification_date,
      documents: documents,
      hearing_request_type: hearing_request_type,
      video_hearing_requested: video_hearing_requested,
      appellant_first_name: "Joe",
      appellant_middle_initial: "E",
      appellant_last_name: "Tester",
      decision_date: decision_date,
      manifest_vbms_fetched_at: appeal_manifest_vbms_fetched_at,
      manifest_vva_fetched_at: appeal_manifest_vva_fetched_at,
      location_code: location_code,
      status: status,
      disposition: disposition
    )
  end

  let(:appeal_no_appellant) do
    Generators::Appeal.build(
      nod_date: nod_date,
      soc_date: soc_date,
      form9_date: form9_date,
      ssoc_dates: ssoc_dates,
      documents: documents,
      hearing_request_type: hearing_request_type,
      video_hearing_requested: video_hearing_requested,
      appellant_first_name: nil,
      appellant_middle_initial: nil,
      appellant_last_name: nil
    )
  end

  let(:notification_date) { 1.month.ago }
  let(:nod_date) { 3.days.ago }
  let(:soc_date) { 1.day.ago }
  let(:form9_date) { 1.day.ago }
  let(:ssoc_dates) { [] }
  let(:certification_date) { nil }
  let(:decision_date) { nil }
  let(:documents) { [] }
  let(:hearing_request_type) { :central_office }
  let(:video_hearing_requested) { false }
  let(:location_code) { nil }
  let(:status) { "Advance" }
  let(:disposition) { nil }

  let(:yesterday) { 1.day.ago.to_formatted_s(:short_date) }
  let(:twenty_days_ago) { 20.days.ago.to_formatted_s(:short_date) }
  let(:last_year) { 365.days.ago.to_formatted_s(:short_date) }

  let(:appeal_manifest_vbms_fetched_at) { Time.zone.local(1954, "mar", 16, 8, 2, 55) }
  let(:appeal_manifest_vva_fetched_at) { Time.zone.local(1987, "mar", 15, 20, 15, 1) }

  let(:service_manifest_vbms_fetched_at) { Time.zone.local(1989, "nov", 23, 8, 2, 55) }
  let(:service_manifest_vva_fetched_at) { Time.zone.local(1989, "dec", 13, 20, 15, 1) }

  let!(:efolder_fetched_at_format) { "%FT%T.%LZ" }
  let(:doc_struct) do
    {
      documents: documents,
      manifest_vbms_fetched_at: service_manifest_vbms_fetched_at.utc.strftime(efolder_fetched_at_format),
      manifest_vva_fetched_at: service_manifest_vva_fetched_at.utc.strftime(efolder_fetched_at_format)
    }
  end

  context "#documents_with_type" do
    subject { appeal.documents_with_type(*type) }
    before do
      appeal.documents += [
        Document.new(type: "NOD", received_at: 7.days.ago),
        Document.new(type: "BVA Decision", received_at: 7.days.ago),
        Document.new(type: "BVA Decision", received_at: 6.days.ago),
        Document.new(type: "SSOC", received_at: 6.days.ago)
      ]
    end

    context "when 1 type is passed" do
      let(:type) { "BVA Decision" }
      it "returns right number of documents and type" do
        expect(subject.count).to eq(2)
        expect(subject.first.type).to eq(type)
      end
    end

    context "when 2 types are passed" do
      let(:type) { %w[NOD SSOC] }
      it "returns right number of documents and type" do
        expect(subject.count).to eq(2)
        expect(subject.first.type).to eq(type.first)
        expect(subject.last.type).to eq(type.last)
      end
    end
  end

  context "#nod" do
    subject { appeal.nod }
    it { is_expected.to have_attributes(type: "NOD", vacols_date: appeal.nod_date) }

    context "when nod_date is nil" do
      let(:nod_date) { nil }
      it { is_expected.to be_nil }
    end
  end

  context "#soc" do
    subject { appeal.soc }
    it { is_expected.to have_attributes(type: "SOC", vacols_date: appeal.soc_date) }

    context "when soc_date is nil" do
      let(:soc_date) { nil }
      it { is_expected.to be_nil }
    end
  end

  context "#form9" do
    subject { appeal.form9 }
    it { is_expected.to have_attributes(type: "Form 9", vacols_date: appeal.form9_date) }

    context "when form9_date is nil" do
      let(:form9_date) { nil }
      it { is_expected.to be_nil }
    end
  end

  context "#aod" do
    subject { appeal.aod }

    it { is_expected.to be_truthy }
  end

  context "#remand_return_date" do
    subject { appeal.remand_return_date }

    context "when the appeal is active" do
      it { is_expected.to eq(nil) }
    end
  end

  context "#ssocs" do
    subject { appeal.ssocs }

    context "when there are no ssoc dates" do
      it { is_expected.to eq([]) }
    end

    context "when there are ssoc dates" do
      let(:ssoc_dates) { [Time.zone.today, (Time.zone.today - 5.days)] }

      it "returns array of ssoc documents" do
        expect(subject.first).to have_attributes(vacols_date: Time.zone.today - 5.days)
        expect(subject.last).to have_attributes(vacols_date: Time.zone.today)
      end
    end
  end

  context "#cavc_decisions" do
    subject { appeal.cavc_decisions }

    let!(:cavc_decision) { Generators::CAVCDecision.build(appeal: appeal) }
    let!(:another_cavc_decision) { Generators::CAVCDecision.build(appeal: appeal) }

    it { is_expected.to eq([cavc_decision, another_cavc_decision]) }
  end

  context "#v1_events" do
    subject { appeal.v1_events }
    let(:soc_date) { 5.days.ago }

    it "returns list of events sorted from oldest to newest by date" do
      expect(subject.length > 1).to be_truthy
      expect(subject.first.date).to eq(5.days.ago)
      expect(subject.first.type).to eq(:soc)
    end
  end

  context "#form9_due_date" do
    subject { appeal.form9_due_date }

    context "when the notification date is within the last year" do
      it { is_expected.to eq((notification_date + 1.year).to_date) }
    end

    context "when the notification date is older" do
      let(:notification_date) { 1.year.ago }
      it { is_expected.to eq((soc_date + 60.days).to_date) }
    end

    context "when missing notification date or soc date" do
      let(:soc_date) { nil }
      it { is_expected.to eq(nil) }
    end
  end

  context "#cavc_due_date" do
    subject { appeal.cavc_due_date }

    context "when there is no decision date" do
      it { is_expected.to eq(nil) }
    end

    context "when there is a decision date" do
      let(:decision_date) { 30.days.ago }
      it { is_expected.to eq(90.days.from_now.to_date) }
    end
  end

  context "#events" do
    subject { appeal.events }

    it "returns list of events" do
      expect(!subject.empty?).to be_truthy
      expect(subject.count { |event| event.type == :claim_decision } > 0).to be_truthy
      expect(subject.count { |event| event.type == :nod } > 0).to be_truthy
      expect(subject.count { |event| event.type == :soc } > 0).to be_truthy
      expect(subject.count { |event| event.type == :form9 } > 0).to be_truthy
    end
  end

  context "#documents_match?" do
    let(:nod_document) { Document.new(type: "NOD", received_at: 3.days.ago) }
    let(:soc_document) { Document.new(type: "SOC", received_at: 2.days.ago) }
    let(:form9_document) { Document.new(type: nil, alt_types: ["Form 9"], received_at: 1.day.ago) }

    let(:documents) { [nod_document, soc_document, form9_document] }

    subject { appeal.documents_match? }

    context "when there is an nod, soc, and form9 document matching the respective dates" do
      it { is_expected.to be_truthy }

      context "when ssoc dates don't match" do
        before do
          appeal.documents += [
            Document.new(type: "SSOC", received_at: 6.days.ago, vbms_document_id: "1234"),
            Document.new(type: "SSOC", received_at: 7.days.ago, vbms_document_id: "1235")
          ]
          appeal.ssoc_dates = [2.days.ago, 7.days.ago, 8.days.ago]
        end

        it { is_expected.to be_falsy }
      end

      context "when received_at is nil" do
        before do
          appeal.documents += [
            Document.new(type: "SSOC", received_at: nil, vbms_document_id: "1234"),
            Document.new(type: "SSOC", received_at: 7.days.ago, vbms_document_id: "1235")
          ]
          appeal.ssoc_dates = [2.days.ago, 7.days.ago]
        end

        it { is_expected.to be_falsy }
      end

      context "and ssoc dates match" do
        before do
          # vbms documents
          appeal.documents += [
            Document.new(type: "SSOC", received_at: 9.days.ago, vbms_document_id: "1234"),
            Document.new(type: "SSOC", received_at: 6.days.ago, vbms_document_id: "1235"),
            Document.new(type: "SSOC", received_at: 7.days.ago, vbms_document_id: "1236")
          ]
          # vacols dates
          appeal.ssoc_dates = [2.days.ago, 8.days.ago, 7.days.ago]
        end

        it { is_expected.to be_truthy }
      end
    end

    context "when the nod date is mismatched" do
      before { nod_document.received_at = 5.days.ago }
      it { is_expected.to be_falsy }
    end

    context "when the soc date is mismatched" do
      before { soc_document.received_at = 6.days.ago }
      it { is_expected.to be_falsy }
    end

    context "when the form9 date is mismatched" do
      before { form9_document.received_at = 5.days.ago }
      it { is_expected.to be_falsy }
    end

    context "when at least one ssoc doesn't match" do
      before do
        appeal.documents += [
          Document.new(type: "SSOC", received_at: 6.days.ago),
          Document.new(type: "SSOC", received_at: 7.days.ago)
        ]

        appeal.ssoc_dates = [6.days.ago, 9.days.ago]
      end

      it { is_expected.to be_falsy }
    end

    context "when one of the dates is missing" do
      before { appeal.nod_date = nil }
      it { is_expected.to be_falsy }
    end
  end

  context "#serialized_decision_date" do
    let(:appeal) { Appeal.new(decision_date: decision_date) }
    subject { appeal.serialized_decision_date }

    context "when decision date is nil" do
      let(:decision_date) { nil }
      it { is_expected.to eq("") }
    end

    context "when decision date exists" do
      let(:decision_date) { Time.zone.local(2016, 9, 6) }
      it { is_expected.to eq("2016/09/06") }
    end
  end

  context "#number_of_documents" do
    let(:documents) do
      [Generators::Document.build(type: "NOD"),
       Generators::Document.build(type: "SOC"),
       Generators::Document.build(type: "SSOC")]
    end

    let(:appeal) do
      Generators::Appeal.build(documents: documents)
    end

    subject { appeal.number_of_documents }

    it "should return number of documents" do
      expect(subject).to eq 3
    end
  end

  context "#number_of_documents_after_certification" do
    let(:documents) do
      [Generators::Document.build(type: "NOD", received_at: 4.days.ago),
       Generators::Document.build(type: "SOC", received_at: 1.day.ago),
       Generators::Document.build(type: "SSOC", received_at: 5.days.ago)]
    end

    let(:appeal) do
      Generators::Appeal.build(documents: documents, certification_date: certification_date)
    end

    subject { appeal.number_of_documents_after_certification }

    context "when certification_date is nil" do
      let(:certification_date) { nil }

      it { is_expected.to eq 0 }
    end

    context "when certification_date is set" do
      let(:certification_date) { 2.days.ago }

      it { is_expected.to eq 1 }
    end
  end

  context "#find_or_create_documents_v2!" do
    before do
      FeatureToggle.enable!(:efolder_docs_api)
      FeatureToggle.enable!(:efolder_api_v2)
      RequestStore.store[:application] = "reader"
    end

    after do
      FeatureToggle.disable!(:efolder_docs_api)
      FeatureToggle.disable!(:efolder_api_v2)
    end
    let(:series_id) { "TEST_SERIES_ID" }

    let(:documents) do
      [Generators::Document.build(type: "NOD", series_id: series_id), Generators::Document.build(type: "SOC")]
    end

    context "when there is no existing document" do
      before do
        expect(EFolderService).to receive(:fetch_documents_for).and_return(doc_struct).once
      end

      it "saves retrieved documents" do
        returned_documents = appeal.find_or_create_documents_v2!
        expect(returned_documents.map(&:type)).to eq(documents.map(&:type))

        expect(Document.count).to eq(documents.count)
        expect(Document.first.type).to eq(documents[0].type)
        expect(Document.first.received_at).to eq(documents[0].received_at)
      end
    end

    context "when there are documents with same series_id" do
      let!(:saved_documents) do
        [
          Generators::Document.create(type: "Form 9", series_id: series_id, category_procedural: true),
          Generators::Document.create(type: "NOD", series_id: series_id, category_medical: true)
        ]
      end

      before do
        expect(EFolderService).to receive(:fetch_documents_for).and_return(doc_struct).once
      end

      it "adds new retrieved documents" do
        expect(Document.count).to eq(2)
        expect(Document.first.type).to eq(saved_documents[0].type)

        returned_documents = appeal.find_or_create_documents_v2!
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

          appeal.find_or_create_documents_v2!

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
            appeal.find_or_create_documents_v2!

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

          returned_documents = appeal.find_or_create_documents_v2!
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
        expect(EFolderService).to receive(:fetch_documents_for).and_return(doc_struct).once
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

        returned_documents = appeal.find_or_create_documents_v2!
        expect(returned_documents.map(&:type)).to eq(documents.map(&:type))

        # Adds series id to existing document
        expect(Document.first.series_id).to eq(series_id)
        expect(Document.count).to eq(3)
      end
    end
  end

  context "#find_or_create_documents!" do
    before do
      FeatureToggle.enable!(:efolder_docs_api)
      RequestStore.store[:application] = "reader"
    end

    after do
      FeatureToggle.disable!(:efolder_docs_api)
    end
    let(:vbms_document_id) { "TEST_VBMS_DOCUMENT_ID" }

    let(:documents) do
      [
        Generators::Document.build(
          type: "NOD",
          vbms_document_id: vbms_document_id
        ),
        Generators::Document.build(type: "SOC")
      ]
    end

    context "when there is no existing document" do
      before do
        expect(EFolderService).to receive(:fetch_documents_for).and_return(doc_struct).once
      end

      it "saves retrieved documents" do
        returned_documents = appeal.find_or_create_documents!
        expect(returned_documents.map(&:type)).to eq(documents.map(&:type))

        expect(Document.count).to eq(documents.count)
        expect(Document.first.type).to eq(documents[0].type)
        expect(Document.first.received_at).to eq(documents[0].received_at)
      end
    end

    context "when there is a document with same vbms_document_id" do
      let!(:saved_document) { Generators::Document.create(type: "Form 9", vbms_document_id: vbms_document_id) }

      before do
        expect(EFolderService).to receive(:fetch_documents_for).and_return(doc_struct).once
      end

      it "updates retrieved documents" do
        expect(Document.count).to eq(1)
        expect(Document.first.type).to eq(saved_document.type)

        returned_documents = appeal.find_or_create_documents!
        expect(returned_documents.map(&:type)).to eq(documents.map(&:type))

        expect(Document.count).to eq(documents.count)
        expect(Document.first.type).to eq("NOD")
      end
    end
  end

  context "#fetch_documents!" do
    let(:documents) do
      [Generators::Document.build(type: "NOD"), Generators::Document.build(type: "SOC")]
    end

    let(:appeal) do
      Generators::Appeal.build(documents: documents)
    end

    let(:result) { appeal.fetch_documents!(save: save) }

    context "when save is false" do
      let(:save) { false }
      it "should return documents not saved in the database" do
        expect(result.first).to_not be_persisted
      end

      context "when efolder_docs_api is disabled" do
        it "loads document content from the VBMS service" do
          expect(VBMSService).to receive(:fetch_documents_for).and_return(doc_struct).once
          expect(EFolderService).not_to receive(:fetch_documents_for)
          expect(result).to eq(documents)
        end

        context "when application is reader" do
          before { RequestStore.store[:application] = "reader" }

          it "loads document content from the VBMS service" do
            expect(VBMSService).to receive(:fetch_documents_for).and_return(doc_struct).once
            expect(EFolderService).not_to receive(:fetch_documents_for)
            expect(appeal.fetch_documents!(save: save)).to eq(documents)
          end
        end
      end

      context "when efolder_docs_api is enabled and application is reader" do
        before do
          FeatureToggle.enable!(:efolder_docs_api)
          RequestStore.store[:application] = "reader"
        end

        it "loads document content from the efolder service and sets fetched_at attributes" do
          expect(Appeal).not_to receive(:vbms)
          expect(EFolderService).to receive(:fetch_documents_for).and_return(doc_struct).once
          expect(appeal.fetch_documents!(save: save)).to eq(documents)

          expect(EFolderService).not_to receive(:fetch_documents_for)
          expect(appeal.manifest_vbms_fetched_at).to eq(service_manifest_vbms_fetched_at)
          expect(appeal.manifest_vva_fetched_at).to eq(service_manifest_vva_fetched_at)
        end

        after do
          FeatureToggle.disable!(:efolder_docs_api)
        end
      end
    end

    context "when save is true" do
      let(:save) { true }

      context "when document exists in the database" do
        let!(:existing_document) do
          Generators::Document.create(vbms_document_id: documents[0].vbms_document_id)
        end

        it "should return existing document" do
          p "result: #{result}"
          expect(result.first.id).to eq(existing_document.id)
        end
      end

      context "when efolder_docs_api is disabled" do
        it "loads document content from the VBMS service" do
          expect(VBMSService).to receive(:fetch_documents_for).and_return(doc_struct).once
          expect(EFolderService).not_to receive(:fetch_documents_for)
          expect(result).to eq(documents)
        end
      end

      context "when efolder_docs_api is enabled and application is reader" do
        before do
          FeatureToggle.enable!(:efolder_docs_api)
          RequestStore.store[:application] = "reader"
        end

        it "loads document content from the efolder service" do
          expect(Appeal).not_to receive(:vbms)
          expect(EFolderService).to receive(:fetch_documents_for).and_return(doc_struct).once
          expect(appeal.fetch_documents!(save: save)).to eq(documents)
        end

        after do
          FeatureToggle.disable!(:efolder_docs_api)
        end
      end

      context "when document doesn't exist in the database" do
        it "should return documents saved in the database" do
          expect(result.first).to be_persisted
        end
      end
    end
  end

  context "#manifest_vva_fetched_at" do
    let(:documents) do
      [Generators::Document.build(type: "NOD"), Generators::Document.build(type: "SOC")]
    end
    context "instance variables for appeal not yet set" do
      it "returns own attribute and sets manifest_vbms_fetched_at when called" do
        expect(appeal.manifest_vva_fetched_at).to eq(appeal_manifest_vva_fetched_at)

        expect(EFolderService).not_to receive(:fetch_documents_for)
        expect(VBMSService).not_to receive(:fetch_documents_for)
        expect(appeal.manifest_vbms_fetched_at).to eq(appeal_manifest_vbms_fetched_at)
      end
    end
  end

  context "#manifest_vbms_fetched_at" do
    let(:documents) do
      [Generators::Document.build(type: "NOD"), Generators::Document.build(type: "SOC")]
    end

    it "returns own attribute and sets manifest_vva_fetched_at when called" do
      expect(appeal.manifest_vbms_fetched_at).to eq(appeal_manifest_vbms_fetched_at)

      expect(EFolderService).not_to receive(:fetch_documents_for)
      expect(VBMSService).not_to receive(:fetch_documents_for)
      expect(appeal.manifest_vva_fetched_at).to eq(appeal_manifest_vva_fetched_at)
    end
  end

  context "#in_location?" do
    subject { appeal.in_location?(location) }
    let(:location) { :remand_returned_to_bva }

    context "when location is not recognized" do
      let(:location) { :never_never_land }

      it "raises error" do
        expect { subject }.to raise_error(Appeal::UnknownLocationError)
      end
    end

    context "when is in location" do
      let(:location_code) { "96" }
      it { is_expected.to be_truthy }
    end

    context "when is not in location" do
      let(:location_code) { "97" }
      it { is_expected.to be_falsey }
    end
  end

  context "#case_assignment_exists" do
    subject { appeal.case_assignment_exists }

    it { is_expected.to be_truthy }
  end

  context ".find_or_create_by_vacols_id" do
    let!(:vacols_appeal) do
      Generators::Appeal.build(vacols_id: "123C", vbms_id: "456VBMS")
    end

    subject { Appeal.find_or_create_by_vacols_id("123C") }

    context "when no appeal exists for VACOLS id" do
      context "when no VACOLS data exists for that appeal" do
        before { Fakes::AppealRepository.clean! }

        it "raises ActiveRecord::RecordNotFound error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when VACOLS data exists for that appeal" do
        it "saves and returns that appeal with updated VACOLS data loaded" do
          is_expected.to be_persisted
          expect(subject.vbms_id).to eq("456VBMS")
        end
      end
    end

    context "when appeal with VACOLS id exists in the DB" do
      before { vacols_appeal.save! }

      context "when no VACOLS data exists for that appeal" do
        before { Fakes::AppealRepository.clean! }

        it "raises ActiveRecord::RecordNotFound error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when VACOLS data exists for that appeal" do
        let!(:updated_vacols_appeal) do
          Generators::Appeal.build(vacols_id: "123C", vbms_id: "789VBMS")
        end

        it "saves and returns that appeal with updated VACOLS data loaded" do
          expect(subject.reload.id).to eq(vacols_appeal.id)
          expect(subject.vbms_id).to eq("789VBMS")
        end
      end
    end

    context "sets the vacols_id" do
      before do
        allow_any_instance_of(Appeal).to receive(:save) {}
      end

      it do
        is_expected.to be_an_instance_of(Appeal)
        expect(subject.vacols_id).to eq("123C")
      end
    end

    it "persists in database" do
      expect(Appeal.find_by(vacols_id: subject.vacols_id)).to be_an_instance_of(Appeal)
    end
  end

  context ".close" do
    let(:vacols_record) { :ready_to_certify }
    let(:issues) { [] }
    let(:appeal) { Generators::Appeal.build(vacols_record: vacols_record, issues: issues, nod_date: nod_date) }
    let(:another_appeal) { Generators::Appeal.build(vacols_record: :remand_decided, nod_date: nod_date) }
    let(:user) { Generators::User.build }
    let(:disposition) { "RAMP Opt-in" }
    let(:election_receipt_date) { 2.days.ago }

    context "when called with both appeal and appeals" do
      let(:vacols_record) { :ready_to_certify }

      it "should raise error" do
        expect do
          Appeal.close(
            appeal: appeal,
            appeals: [appeal, another_appeal],
            user: user,
            closed_on: 4.days.ago,
            disposition: disposition,
            election_receipt_date: election_receipt_date
          )
        end.to raise_error("Only pass either appeal or appeals")
      end
    end

    context "when multiple appeals" do
      let(:appeal_with_nod_after_election_received) do
        Generators::Appeal.build(vacols_record: vacols_record, nod_date: 1.day.ago)
      end

      it "closes each appeal with nod_date before election received_date" do
        expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).with(
          appeal: appeal,
          user: user,
          closed_on: 4.days.ago,
          disposition_code: "P"
        )
        expect(Fakes::AppealRepository).to receive(:close_remand!).with(
          appeal: another_appeal,
          user: user,
          closed_on: 4.days.ago,
          disposition_code: "P"
        )
        expect(Fakes::AppealRepository).to_not receive(:close_undecided_appeal!).with(
          appeal: appeal_with_nod_after_election_received,
          user: user,
          closed_on: 4.days.ago,
          disposition_code: "P"
        )

        Appeal.close(
          appeals: [appeal, another_appeal, appeal_with_nod_after_election_received],
          user: user,
          closed_on: 4.days.ago,
          disposition: disposition,
          election_receipt_date: election_receipt_date
        )
      end
    end

    context "when just one appeal" do
      subject do
        Appeal.close(
          appeal: appeal,
          user: user,
          closed_on: 4.days.ago,
          disposition: disposition,
          election_receipt_date: election_receipt_date
        )
      end

      context "when disposition is not valid" do
        let(:disposition) { "I'm not a disposition" }

        it "should raise error" do
          expect { subject }.to raise_error(/Disposition/)
        end
      end

      context "when disposition is valid" do
        context "when appeal is not active" do
          let(:vacols_record) { :full_grant_decided }

          it "should raise error" do
            expect { subject }.to raise_error(/active/)
          end
        end

        context "when appeal is active and undecided" do
          let(:vacols_record) { :ready_to_certify }

          it "closes the appeal in VACOLS" do
            expect(Fakes::AppealRepository).to receive(:close_undecided_appeal!).with(
              appeal: appeal,
              user: user,
              closed_on: 4.days.ago,
              disposition_code: "P"
            )

            subject
          end
        end

        context "when appeal is a remand" do
          let(:vacols_record) { :remand_decided }

          # Add non_new_material_allowed issue to make sure it still works
          let(:issues) do
            [Generators::Issue.build(disposition: :allowed)]
          end

          it "closes the remand in VACOLS" do
            expect(Fakes::AppealRepository).to receive(:close_remand!).with(
              appeal: appeal,
              user: user,
              closed_on: 4.days.ago,
              disposition_code: "P"
            )

            subject
          end
        end
      end
    end
  end

  context ".reopen" do
    subject do
      Appeal.reopen(
        appeals: [appeal, another_appeal],
        user: user,
        disposition: disposition
      )
    end

    let(:appeal) { Generators::Appeal.build(vacols_record: :ramp_closed) }
    let(:another_appeal) { Generators::Appeal.build(vacols_record: :remand_completed) }
    let(:user) { Generators::User.build }
    let(:disposition) { "RAMP Opt-in" }

    it "reopens each appeal according to it's type" do
      expect(Fakes::AppealRepository).to receive(:reopen_undecided_appeal!).with(
        appeal: appeal,
        user: user
      )

      expect(Fakes::AppealRepository).to receive(:reopen_remand!).with(
        appeal: another_appeal,
        user: user,
        disposition_code: "P"
      )

      subject
    end

    context "disposition doesn't exist" do
      let(:disposition) { "I'm not a disposition" }

      it "should raise error" do
        expect { subject }.to raise_error(/Disposition/)
      end
    end

    context "one of the non-remand appeals is active" do
      let(:appeal) { Generators::Appeal.build(vacols_record: :ready_to_certify) }

      it "should raise error" do
        expect { subject }.to raise_error("Only closed appeals can be reopened")
      end
    end
  end

  context "#certify!" do
    let(:appeal) { Appeal.new(vacols_id: "765") }
    subject { appeal.certify! }

    context "when form8 for appeal exists in the DB" do
      before do
        @form8 = Form8.create(vacols_id: "765")
        @certification = Certification.create(vacols_id: "765")
      end

      it "certifies the appeal using AppealRepository" do
        expect { subject }.to_not raise_error
        expect(Fakes::AppealRepository.certified_appeal).to eq(appeal)
      end

      it "uploads the correct form 8 using AppealRepository" do
        expect { subject }.to_not raise_error
        expect(Fakes::VBMSService.uploaded_form8.id).to eq(@form8.id)
        expect(Fakes::VBMSService.uploaded_form8_appeal).to eq(appeal)
      end
    end

    context "when a cancelled certification for an appeal already exists in the DB" do
      before do
        @form8 = Form8.create(vacols_id: "765")
        @cancelled_certification = Certification.create!(
          vacols_id: "765", hearing_preference: "SOME_INVALID_PREF"
        )
        CertificationCancellation.create!(
          certification_id: @cancelled_certification.id,
          cancellation_reason: "reason",
          email: "test@caseflow.gov"
        )
        @certification = Certification.create!(vacols_id: "765", hearing_preference: "VIDEO")
      end

      it "certifies the correct appeal using AppealRepository" do
        expect { subject }.to_not raise_error
        expect(Fakes::AppealRepository.certification).to eq(@certification)
      end
    end

    context "when form8 doesn't exist in the DB for appeal" do
      it "throws an error" do
        expect { subject }.to raise_error("No Form 8 found for appeal being certified")
      end
    end
  end

  context "#certified?" do
    subject { Appeal.new(certification_date: 2.days.ago) }

    it "reads certification date off the appeal" do
      expect(subject.certified?).to be_truthy
      subject.certification_date = nil
      expect(subject.certified?).to be_falsy
    end
  end

  context "#hearing_pending?" do
    subject { Appeal.new(hearing_requested: false, hearing_held: false) }

    it "determines whether an appeal is awaiting a hearing" do
      expect(subject.hearing_pending?).to be_falsy
      subject.hearing_requested = true
      expect(subject.hearing_pending?).to be_truthy
      subject.hearing_held = true
      expect(subject.hearing_pending?).to be_falsy
    end
  end

  context "#sanitized_vbms_id" do
    subject { Appeal.new(vbms_id: "123C") }

    it "left-pads case-number ids" do
      expect(subject.sanitized_vbms_id).to eq("00000123")
    end

    it "left-pads 7-digit case-number ids" do
      subject.vbms_id = "2923988C"
      expect(subject.sanitized_vbms_id).to eq("02923988")
    end

    it "doesn't left-pad social security ids" do
      subject.vbms_id = "123S"
      expect(subject.sanitized_vbms_id).to eq("123")
    end
  end

  context "#fetch_appeals_by_file_number" do
    subject { Appeal.fetch_appeals_by_file_number(file_number) }
    let!(:appeal) do
      Generators::Appeal.build(vacols_id: "123C", vbms_id: "123456789S")
    end

    context "when passed with valid vbms id" do
      let(:file_number) { "123456789" }

      it "returns an appeal" do
        expect(subject.length).to eq(1)
        expect(subject[0].vbms_id).to eq("123456789S")
      end
    end

    context "when passed an invalid vbms id" do
      context "length greater than 9" do
        let(:file_number) { "1234567890" }

        it "raises ActiveRecord::RecordNotFound error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "length less than 3" do
        let(:file_number) { "12" }

        it "raises ActiveRecord::RecordNotFound error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  context ".convert_file_number_to_vacols" do
    subject { Appeal.convert_file_number_to_vacols(file_number) }

    context "for a file number with less than 9 digits" do
      context "with leading zeros" do
        let(:file_number) { "00001234" }
        it { is_expected.to eq("1234C") }
      end

      context "with no leading zeros" do
        let(:file_number) { "12345678" }
        it { is_expected.to eq("12345678C") }
      end
    end

    context "for a file number with 9 digits" do
      let(:file_number) { "123456789" }
      it { is_expected.to eq("123456789S") }

      context "with letters" do
        let(:file_number) { "12ABCSD34ASDASD56789S" }
        it { is_expected.to eq("123456789S") }
      end

      context "with leading zeros and letters" do
        let(:file_number) { "00123C00S9S" }
        it { is_expected.to eq("123009C") }
      end
    end

    context "for a file number with more than 9 digits" do
      let(:file_number) { "1234567890" }

      it "raises InvalidFileNumber error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidFileNumber)
      end
    end
  end

  context "#partial_grant_on_dispatch?" do
    let(:appeal) { Generators::Appeal.build(vacols_id: "123", status: "Remand", issues: issues) }
    subject { appeal.partial_grant_on_dispatch? }

    context "when no allowed issues" do
      let(:issues) { [Generators::Issue.build(disposition: :remanded)] }

      it { is_expected.to be_falsey }
    end

    context "when the allowed issues are new material" do
      let(:issues) { [Generators::Issue.build(disposition: :allowed, codes: %w[02 15 04 5252])] }

      it { is_expected.to be_falsey }
    end

    context "when there's a mix of allowed and remanded issues" do
      let(:issues) do
        [
          Generators::Issue.build(disposition: :allowed),
          Generators::Issue.build(disposition: :remanded)
        ]
      end

      it { is_expected.to be_truthy }
    end
  end

  context "#full_grant_on_dispatch?" do
    let(:issues) { [] }
    let(:appeal) do
      Generators::Appeal.build(vacols_id: "123", status: status, issues: issues)
    end
    subject { appeal.full_grant_on_dispatch? }

    context "when status is Remand" do
      let(:status) { "Remand" }
      it { is_expected.to be_falsey }
    end

    context "when status is Complete" do
      let(:status) { "Complete" }

      context "when at least one issues is new-material allowed" do
        let(:issues) do
          [
            Generators::Issue.build(disposition: :allowed, codes: %w[02 15 04 5252]),
            Generators::Issue.build(disposition: :denied)
          ]
        end
        it { is_expected.to be_falsey }
      end

      context "when at least one issue is not new-material allowed" do
        let(:issues) do
          [
            Generators::Issue.build(disposition: :allowed),
            Generators::Issue.build(disposition: :denied)
          ]
        end
        it { is_expected.to be_truthy }
      end
    end
  end

  context "#remand_on_dispatch?" do
    subject { appeal.remand_on_dispatch? }

    context "status is not remand" do
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", status: "Complete") }
      it { is_expected.to be false }
    end

    context "status is remand" do
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", status: "Remand", issues: issues) }

      context "contains at least one new-material allowed issue" do
        let(:issues) do
          [
            Generators::Issue.build(disposition: :allowed),
            Generators::Issue.build(disposition: :remanded)
          ]
        end

        it { is_expected.to be false }
      end

      context "contains no new-material allowed issues" do
        let(:issues) do
          [
            Generators::Issue.build(disposition: :allowed, codes: %w[02 15 04 5252]),
            Generators::Issue.build(disposition: :remanded)
          ]
        end

        it { is_expected.to be true }
      end
    end
  end

  context "#decided_by_bva?" do
    let(:appeal) do
      Generators::Appeal.build(vacols_id: "123", status: status, disposition: disposition)
    end

    subject { appeal.decided_by_bva? }

    let(:disposition) { "Remanded" }

    context "when status is not Complete" do
      let(:status) { "Remand" }
      it { is_expected.to be false }
    end

    context "when status is Complete" do
      let(:status) { "Complete" }

      context "when disposition is a BVA disposition" do
        it { is_expected.to be true }
      end

      context "when disposition is not a BVA disposition" do
        let(:disposition) { "Advance Allowed in Field" }
        it { is_expected.to be false }
      end
    end
  end

  context "#compensation_issues" do
    subject { appeal.compensation_issues }

    let(:appeal) { Generators::Appeal.build(issues: issues) }
    let(:compensation_issue) { Generators::Issue.build(template: :compensation) }
    let(:issues) { [Generators::Issue.build(template: :education), compensation_issue] }

    it { is_expected.to eq([compensation_issue]) }
  end

  context "#compensation?" do
    subject { appeal.compensation? }

    let(:appeal) { Generators::Appeal.build(issues: issues) }
    let(:compensation_issue) { Generators::Issue.build(template: :compensation) }
    let(:education_issue) { Generators::Issue.build(template: :education) }

    context "when there are no compensation issues" do
      let(:issues) { [education_issue] }
      it { is_expected.to be false }
    end

    context "when there is at least 1 compensation issue" do
      let(:issues) { [education_issue, compensation_issue] }
      it { is_expected.to be true }
    end
  end

  context "#fully_compensation?" do
    subject { appeal.fully_compensation? }

    let(:appeal) { Generators::Appeal.build(issues: issues) }
    let(:compensation_issue) { Generators::Issue.build(template: :compensation) }
    let(:education_issue) { Generators::Issue.build(template: :education) }

    context "when there is at least one non-compensation issue" do
      let(:issues) { [education_issue, compensation_issue] }
      it { is_expected.to be false }
    end

    context "when there are all compensation issues" do
      let(:issues) { [compensation_issue] }
      it { is_expected.to be true }
    end
  end

  context "#eligible_for_ramp?" do
    subject { appeal.eligible_for_ramp? }

    let(:appeal) do
      Generators::Appeal.build(vacols_id: "123", status: status, location_code: location_code)
    end

    let(:location_code) { nil }

    context "is false if status is not advance or remand" do
      let(:status) { "Active" }
      it { is_expected.to be_falsey }
    end

    context "status is remand" do
      let(:status) { "Remand" }
      it { is_expected.to be_truthy }
    end

    context "status is advance" do
      let(:status) { "Advance" }

      context "location is remand_returned_to_bva" do
        let(:location_code) { "96" }
        it { is_expected.to be_falsey }
      end

      context "location is not remand_returned_to_bva" do
        let(:location_code) { "90" }
        it { is_expected.to be_truthy }
      end
    end
  end

  context "#disposition_remand_priority" do
    subject { appeal.disposition_remand_priority }
    context "when disposition is allowed and one of the issues is remanded" do
      let(:issues) do
        [
          Generators::Issue.build(disposition: :allowed),
          Generators::Issue.build(disposition: :remanded)
        ]
      end
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", issues: issues, disposition: "Allowed") }
      it { is_expected.to eq("Remanded") }
    end

    context "when disposition is allowed and none of the issues are remanded" do
      let(:issues) do
        [
          Generators::Issue.build(disposition: :allowed),
          Generators::Issue.build(disposition: :allowed)
        ]
      end
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", issues: issues, disposition: "Allowed") }
      it { is_expected.to eq("Allowed") }
    end

    context "when disposition is not allowed" do
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", issues: [], disposition: "Vacated") }
      it { is_expected.to eq("Vacated") }
    end
  end

  context "#dispatch_decision_type" do
    subject { appeal.dispatch_decision_type }
    context "when it has a mix of allowed and granted issues" do
      let(:issues) do
        [
          Generators::Issue.build(disposition: :allowed),
          Generators::Issue.build(disposition: :remanded)
        ]
      end
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", status: "Remand", issues: issues) }
      it { is_expected.to eq("Partial Grant") }
    end

    context "when it has a non-new-material allowed issue" do
      let(:issues) { [Generators::Issue.build(disposition: :allowed)] }
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", status: "Complete", issues: issues) }
      it { is_expected.to eq("Full Grant") }
    end

    context "when it has a remanded issue" do
      let(:issues) { [Generators::Issue.build(disposition: :remand)] }
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", status: "Remand") }
      it { is_expected.to eq("Remand") }
    end
  end

  context "#task_header" do
    let(:appeal) do
      Appeal.new(
        veteran_first_name: "Davy",
        veteran_middle_initial: "Q",
        veteran_last_name: "Crockett",
        vbms_id: "123"
      )
    end

    subject { appeal.task_header }

    it "returns the correct string" do
      expect(subject).to eq("&nbsp &#124; &nbsp Crockett, Davy, Q (123)")
    end
  end

  context "#outcoded_by_name" do
    let(:appeal) do
      Appeal.new(
        outcoder_last_name: "King",
        outcoder_middle_initial: "Q",
        outcoder_first_name: "Andrew"
      )
    end

    subject { appeal.outcoded_by_name }

    it "returns the correct string" do
      expect(subject).to eq("King, Andrew, Q")
    end
  end

  context "#station_key" do
    let(:appeal) do
      Appeal.new(
        veteran_first_name: "Davy",
        veteran_middle_initial: "Q",
        veteran_last_name: "Crockett",
        regional_office_key: regional_office_key
      )
    end

    subject { appeal.station_key }

    context "when regional office key is mapped to a station" do
      let(:regional_office_key) { "RO13" }
      it { is_expected.to eq("313") }
    end

    context "when regional office key is one of many mapped to a station" do
      let(:regional_office_key) { "RO16" }
      it { is_expected.to eq("316") }
    end

    context "when regional office key is not mapped to a station" do
      let(:regional_office_key) { "SO62" }
      it { is_expected.to be_nil }
    end
  end

  context "#decisions" do
    subject { appeal.decisions }
    let(:decision) do
      Document.new(received_at: Time.zone.now.to_date, type: "BVA Decision")
    end
    let(:old_decision) do
      Document.new(received_at: 5.days.ago.to_date, type: "BVA Decision")
    end
    let(:appeal) { Appeal.new(vbms_id: "123") }

    context "when only one decision" do
      before do
        appeal.documents = [decision]
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([decision]) }
    end

    context "when only one recent decision" do
      before do
        appeal.documents = [decision, old_decision]
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([decision]) }
    end

    context "when no recent decision" do
      before do
        appeal.documents = [old_decision]
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([]) }
    end

    context "when no decision_date on appeal" do
      before do
        appeal.decision_date = nil
      end

      it { is_expected.to eq([]) }
    end

    context "when there are two decisions of the same type" do
      let(:documents) { [decision, decision.clone] }

      before do
        appeal.documents = documents
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq(documents) }
    end

    context "when there are two decisions of the different types" do
      let(:documents) do
        [
          decision,
          Document.new(type: "Remand BVA or CAVC", received_at: 1.day.ago)
        ]
      end

      before do
        appeal.documents = documents
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq(documents) }
    end
  end

  context "#non_canceled_end_products_within_30_days" do
    let(:appeal) { Generators::Appeal.build(decision_date: 1.day.ago) }
    let(:result) { appeal.non_canceled_end_products_within_30_days }

    let!(:twenty_day_old_pending_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: twenty_days_ago,
          claim_type_code: "172GRANT",
          status_type_code: "PEND"
        }
      )
    end

    let!(:recent_cleared_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: yesterday,
          claim_type_code: "170RMD",
          status_type_code: "CLR"
        }
      )
    end

    let!(:recent_cancelled_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: yesterday,
          claim_type_code: "172BVAG",
          status_type_code: "CAN"
        }
      )
    end

    let!(:year_old_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: last_year,
          claim_type_code: "172BVAG",
          status_type_code: "CLR"
        }
      )
    end

    it "returns correct eps" do
      puts BGSService.end_product_records
      expect(result.length).to eq(2)

      expect(result.first.claim_type_code).to eq("172GRANT")
      expect(result.last.claim_type_code).to eq("170RMD")
    end
  end

  context "#special_issues?" do
    let(:appeal) { Appeal.new(vacols_id: "123", us_territory_claim_philippines: true) }
    subject { appeal.special_issues? }

    it "is true if any special issues exist" do
      expect(subject).to be_truthy
    end

    it "is false if no special issues exist" do
      appeal.update!(us_territory_claim_philippines: false)
      expect(subject).to be_falsy
    end
  end

  context "#pending_eps" do
    let(:appeal) { Generators::Appeal.build(decision_date: 1.day.ago) }

    let!(:pending_eps) do
      [
        Generators::EndProduct.build(
          veteran_file_number: appeal.sanitized_vbms_id,
          bgs_attrs: {
            claim_receive_date: twenty_days_ago,
            claim_type_code: "070BVAGR",
            end_product_type_code: "071",
            status_type_code: "PEND"
          }
        ),
        Generators::EndProduct.build(
          veteran_file_number: appeal.sanitized_vbms_id,
          bgs_attrs: {
            claim_receive_date: last_year,
            claim_type_code: "070BVAGRARC",
            end_product_type_code: "070",
            status_type_code: "PEND"
          }
        )
      ]
    end

    let!(:cancelled_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: yesterday,
          claim_type_code: "070RMND",
          end_product_type_code: "072",
          status_type_code: "CAN"
        }
      )
    end

    let!(:cleared_ep) do
      Generators::EndProduct.build(
        veteran_file_number: appeal.sanitized_vbms_id,
        bgs_attrs: {
          claim_receive_date: last_year,
          claim_type_code: "172BVAG",
          status_type_code: "CLR"
        }
      )
    end

    let(:result) { appeal.pending_eps }

    it "returns only pending eps" do
      expect(result.length).to eq(2)

      expect(result.first.claim_type_code).to eq("070BVAGR")
      expect(result.last.claim_type_code).to eq("070BVAGRARC")
    end
  end

  context "#special_issues" do
    subject { appeal.special_issues }

    context "when no special issues are true" do
      it { is_expected.to eq([]) }
    end

    context "when one special issue is true" do
      let(:appeal) { Appeal.new(dic_death_or_accrued_benefits_united_states: true) }
      it { is_expected.to eq(["DIC - death, or accrued benefits - United States"]) }
    end

    context "when many special issues are true" do
      let(:appeal) do
        Appeal.new(
          foreign_claim_compensation_claims_dual_claims_appeals: true,
          vocational_rehab: true,
          education_gi_bill_dependents_educational_assistance_scholars: true,
          us_territory_claim_puerto_rico_and_virgin_islands: true
        )
      end

      it { expect(subject.length).to eq(4) }
      it { is_expected.to include("Foreign claim - compensation claims, dual claims, appeals") }
      it { is_expected.to include("Vocational Rehab") }
      it { is_expected.to include(/Education - GI Bill, dependents educational assistance/) }
      it { is_expected.to include("U.S. Territory claim - Puerto Rico and Virgin Islands") }
    end
  end

  context "#veteran" do
    subject { appeal.veteran }

    let(:veteran_record) { { file_number: "123", first_name: "Ed", last_name: "Merica" } }

    before do
      Fakes::BGSService.veteran_records = { appeal.sanitized_vbms_id => veteran_record }
    end

    it "returns veteran loaded with BGS values" do
      is_expected.to have_attributes(first_name: "Ed", last_name: "Merica")
    end
  end

  context "#power_of_attorney" do
    subject { appeal.power_of_attorney }

    it "returns poa loaded with VACOLS values" do
      is_expected.to have_attributes(
        vacols_representative_type: "Service Organization",
        vacols_representative_name: "The American Legion"
      )
    end

    it "returns poa loaded with BGS values by default" do
      is_expected.to have_attributes(bgs_representative_type: "Attorney", bgs_representative_name: "Clarence Darrow")
    end

    context "#power_of_attorney(load_bgs_record: false)" do
      subject { appeal.power_of_attorney(load_bgs_record: false) }

      it "returns poa without fetching BGS values if desired" do
        is_expected.to have_attributes(bgs_representative_type: nil, bgs_representative_name: nil)
      end
    end

    context "#power_of_attorney.bgs_representative_address" do
      subject { appeal.power_of_attorney.bgs_representative_address }

      it "returns address if we are able to retrieve it" do
        is_expected.to include(
          address_line_1: "9999 MISSION ST",
          city: "SAN FRANCISCO",
          zip: "94103"
        )
      end
    end
  end

  context "#issue_categories" do
    subject { appeal.issue_categories }

    let(:appeal) do
      Generators::Appeal.build(issues: issues)
    end

    let(:issues) do
      [
        Generators::Issue.build(disposition: :allowed, codes: %w[02 01]),
        Generators::Issue.build(disposition: :allowed, codes: %w[02 02]),
        Generators::Issue.build(disposition: :allowed, codes: %w[02 01])
      ]
    end

    it { is_expected.to include("02-01") }
    it { is_expected.to include("02-02") }
    it { is_expected.to_not include("02-03") }
    it "returns uniqued issue categories" do
      expect(subject.length).to eq(2)
    end
  end

  context "#worksheet_issues" do
    subject { appeal.worksheet_issues.size }

    context "when appeal does not have any Vacols issues" do
      let(:appeal) { Generators::Appeal.create(vacols_record: :ready_to_certify) }
      it { is_expected.to eq 0 }
    end

    context "when appeal has Vacols issues" do
      let(:appeal) { Generators::Appeal.create(vacols_record: :remand_decided) }
      it { is_expected.to eq 2 }
    end
  end

  context "#update" do
    subject { appeal.update(appeals_hash) }
    let(:appeal) { Generators::Appeal.create(vacols_record: :form9_not_submitted) }

    context "when Vacols does not need an update" do
      let(:appeals_hash) do
        { worksheet_issues_attributes: [{
          remand: true,
          omo: true,
          description: "Cabbage\nPickle",
          notes: "Donkey\nCow",
          from_vacols: true,
          vacols_sequence_id: 1
        }] }
      end

      it "updates worksheet issues" do
        expect(appeal.worksheet_issues.count).to eq(0)
        subject # do update
        expect(appeal.worksheet_issues.count).to eq(1)

        issue = appeal.worksheet_issues.first
        expect(issue.remand).to eq true
        expect(issue.allow).to eq false
        expect(issue.deny).to eq false
        expect(issue.dismiss).to eq false
        expect(issue.omo).to eq true
        expect(issue.description).to eq "Cabbage\nPickle"
        expect(issue.notes).to eq "Donkey\nCow"

        # test that a 2nd save updates the same record, rather than create new one
        id = appeal.worksheet_issues.first.id
        appeals_hash[:worksheet_issues_attributes][0][:deny] = true
        appeals_hash[:worksheet_issues_attributes][0][:notes] = "Tomato"
        appeals_hash[:worksheet_issues_attributes][0][:id] = id

        appeal.update(appeals_hash)

        expect(appeal.worksheet_issues.count).to eq(1)
        issue = appeal.worksheet_issues.first
        expect(issue.id).to eq(id)
        expect(issue.deny).to eq(true)
        expect(issue.remand).to eq(true)
        expect(issue.allow).to eq(false)
        expect(issue.dismiss).to eq(false)
        expect(issue.description).to eq "Cabbage\nPickle"
        expect(issue.notes).to eq "Tomato"

        # soft delete an issue
        appeals_hash[:worksheet_issues_attributes][0][:_destroy] = "1"
        appeal.update(appeals_hash)
        expect(appeal.worksheet_issues.count).to eq(0)
        expect(appeal.worksheet_issues.with_deleted.count).to eq(1)
        expect(appeal.worksheet_issues.with_deleted.first.deleted_at).to_not eq nil
      end
    end
  end

  context "#sanitized_hearing_request_type" do
    subject { appeal.sanitized_hearing_request_type }
    let(:video_hearing_requested) { true }

    context "when central_office" do
      let(:hearing_request_type) { :central_office }
      it { is_expected.to eq(:central_office) }
    end

    context "when travel_board" do
      let(:hearing_request_type) { :travel_board }

      context "when video_hearing_requested" do
        it { is_expected.to eq(:video) }
      end

      context "when video_hearing_requested is false" do
        let(:video_hearing_requested) { false }
        it { is_expected.to eq(:travel_board) }
      end
    end

    context "when unsupported type" do
      let(:hearing_request_type) { :confirmation_needed }
      it { is_expected.to be_nil }
    end
  end

  context "#appellant_last_first_mi" do
    subject { appeal.appellant_last_first_mi }
    it { is_expected.to eql("Tester, Joe E.") }

    context "when appellant has no first name" do
      subject { appeal_no_appellant.appellant_last_first_mi }
      it { is_expected.to be_nil }
    end
  end

  context ".to_hash" do
    context "when issues parameter is nil and contains additional attributes" do
      subject { appeal.to_hash(viewed: true, issues: nil) }

      let!(:appeal) do
        Generators::Appeal.build(
          vbms_id: "999887777S",
          docket_number: "13 11-265",
          regional_office_key: "RO13",
          type: "Court Remand",
          vacols_record: {
            soc_date: 4.days.ago
          }
        )
      end

      it "includes viewed boolean in hash" do
        expect(subject["viewed"]).to be_truthy
      end

      it "issues is null in hash" do
        expect(subject["issues"]).to be_nil
      end

      it "includes aod, cavc, regional_office and docket_number" do
        expect(subject["aod"]).to be_truthy
        expect(subject["cavc"]).to be_truthy
        expect(subject["regional_office"][:key]).to eq("RO13")
        expect(subject["docket_number"]).to eq("13 11-265")
      end
    end

    context "when issues and viewed attributes are provided" do
      subject { appeal.to_hash(viewed: true, issues: issues) }

      let!(:appeal) do
        Generators::Appeal.build(
          vbms_id: "999887777S",
          vacols_record: { soc_date: 4.days.ago },
          issues: issues
        )
      end

      let!(:labels) do
        ["Compensation", "Service connection", "Other", "Left knee", "Right knee"]
      end

      let!(:issues) do
        [Generators::Issue.build(disposition: :allowed,
                                 codes: %w[02 15 03 04 05],
                                 labels: labels)]
      end

      it "includes viewed boolean in hash" do
        expect(subject["viewed"]).to be_truthy
      end

      it "includes issues in hash" do
        expect(subject["issues"]).to eq(issues.map(&:attributes))
      end
    end
  end

  context ".for_api" do
    subject { Appeal.for_api(vbms_id: "999887777S") }

    let!(:veteran_appeals) do
      [
        Generators::Appeal.build(
          vbms_id: "999887777S",
          vacols_record: { soc_date: 4.days.ago }
        ),
        Generators::Appeal.build(
          vbms_id: "999887777S",
          vacols_record: { type: "Reconsideration" }
        ),
        Generators::Appeal.build(
          vbms_id: "999887777S",
          vacols_record: { form9_date: 3.days.ago }
        ),
        Generators::Appeal.build(
          vbms_id: "999887777S",
          vacols_record: { form9_date: nil }
        )
      ]
    end

    it "returns filtered appeals with events only for veteran sorted by latest event date" do
      expect(subject.length).to eq(2)
      expect(subject.first.form9_date).to eq(3.days.ago)
    end
  end

  context ".initialize_appeal_without_lazy_load",
          skip: "Disabled without_lazy_load for appeals for fixing Welcome Gate" do
    let(:date) { Time.zone.today }
    let(:saved_appeal) do
      Generators::Appeal.build(
        vacols_record: { veteran_first_name: "George" }
      )
    end
    let(:appeal) do
      Appeal.find_or_initialize_by(vacols_id: saved_appeal.vacols_id,
                                   signed_date: date)
    end

    it "creates an appeals object with attributes" do
      expect(appeal.signed_date).to eq(date)
    end

    it "appeal does not lazy load vacols data" do
      expect { appeal.veteran_first_name }.to raise_error(AssociatedVacolsModel::LazyLoadingTurnedOffError)
    end
  end

  context "#vbms_id" do
    context "when vbms_id exists in the caseflow DB" do
      it "does not make a request to VACOLS" do
        expect(appeal).to receive(:perform_vacols_request)
          .exactly(0).times

        expect(appeal.attributes["vbms_id"]).to_not be_nil
        expect(appeal.vbms_id).to_not be_nil
      end
    end

    context "when vbms_id is nil" do
      let(:no_vbms_id_appeal) { Appeal.new(vacols_id: appeal.vacols_id) }

      context "when appeal is in the DB" do
        before { no_vbms_id_appeal.save! }

        it "looks up vbms_id in VACOLS and saves" do
          expect(no_vbms_id_appeal).to receive(:perform_vacols_request)
            .exactly(1).times.and_call_original

          expect(no_vbms_id_appeal.attributes["vbms_id"]).to be_nil
          expect(no_vbms_id_appeal.reload.vbms_id).to_not be_nil
        end
      end

      context "when appeal is not in the DB" do
        it "looks up vbms_id in VACOLS but does not save" do
          expect(no_vbms_id_appeal).to receive(:perform_vacols_request)
            .exactly(1).times.and_call_original

          expect(no_vbms_id_appeal.attributes["vbms_id"]).to be_nil
          expect(no_vbms_id_appeal.vbms_id).to_not be_nil
          expect(no_vbms_id_appeal).to_not be_persisted
        end
      end
    end
  end

  context "#save_to_legacy_appeals" do
    let :appeal do
      Appeal.create!(
        vacols_id: "1234"
      )
    end

    let :legacy_appeal do
      LegacyAppeal.find(appeal.id)
    end

    it "Creates a legacy_appeal when an appeal is created" do
      expect(legacy_appeal).to_not be_nil
      expect(legacy_appeal.attributes).to eq(appeal.attributes)
    end

    it "Updates a legacy_appeal when an appeal is updated" do
      appeal.update!(rice_compliance: TRUE)
      expect(legacy_appeal.attributes).to eq(appeal.attributes)
    end
  end

  context "#destroy_legacy_appeal" do
    let :appeal do
      Appeal.create!(
        id: 1,
        vacols_id: "1234"
      )
    end

    it "Destroys a legacy_appeal when an appeal is destroyed" do
      appeal.destroy!
      expect(LegacyAppeal.where(id: appeal.id)).to_not exist
    end
  end
end
