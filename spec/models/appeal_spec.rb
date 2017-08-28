describe Appeal do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:appeal) do
    Generators::Appeal.build(
      nod_date: nod_date,
      soc_date: soc_date,
      form9_date: form9_date,
      ssoc_dates: ssoc_dates,
      documents: documents,
      hearing_request_type: hearing_request_type,
      video_hearing_requested: video_hearing_requested,
      appellant_first_name: "Joe",
      appellant_middle_initial: "E",
      appellant_last_name: "Tester"
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
      video_hearing_requested: video_hearing_requested
    )
  end

  let(:nod_date) { 3.days.ago }
  let(:soc_date) { 1.day.ago }
  let(:form9_date) { 1.day.ago }
  let(:ssoc_dates) { [] }
  let(:documents) { [] }
  let(:hearing_request_type) { :central_office }
  let(:video_hearing_requested) { false }

  let(:yesterday) { 1.day.ago.to_formatted_s(:short_date) }
  let(:twenty_days_ago) { 20.days.ago.to_formatted_s(:short_date) }
  let(:last_year) { 365.days.ago.to_formatted_s(:short_date) }

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
      let(:type) { %w(NOD SSOC) }
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

  context "#events" do
    subject { appeal.events }
    let(:soc_date) { 5.days.ago }

    it "returns list of events sorted from oldest to newest by date" do
      expect(subject.length > 1).to be_truthy
      expect(subject.first.date).to eq(5.days.ago)
      expect(subject.first.type).to eq(:soc)
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
          expect(VBMSService).to receive(:fetch_documents_for).and_return(documents).once
          expect(EFolderService).not_to receive(:fetch_documents_for)
          expect(result).to eq(documents)
        end

        context "when application is reader" do
          before { RequestStore.store[:application] = "reader" }

          it "loads document content from the VBMS service" do
            expect(VBMSService).to receive(:fetch_documents_for).and_return(documents).once
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

        it "loads document content from the efolder service" do
          expect(Appeal).not_to receive(:vbms)
          expect(EFolderService).to receive(:fetch_documents_for).and_return(documents).once
          expect(appeal.fetch_documents!(save: save)).to eq(documents)
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
          expect(VBMSService).to receive(:fetch_documents_for).and_return(documents).once
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
          expect(EFolderService).to receive(:fetch_documents_for).and_return(documents).once
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

  context "#fetched_documents" do
    let(:documents) do
      [Generators::Document.build(type: "NOD"), Generators::Document.build(type: "SOC")]
    end

    let(:appeal) do
      Generators::Appeal.build(documents: documents)
    end

    subject { appeal.fetched_documents }
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

  context "#fetch_appeals_by_vbms_id" do
    subject { Appeal.fetch_appeals_by_vbms_id(vbms_id) }
    let!(:appeal) do
      Generators::Appeal.build(vacols_id: "123C", vbms_id: "123456789")
    end

    context "when passed with valid vbms id" do
      let(:vbms_id) { "123456789" }

      it "returns an appeal" do
        expect(subject.length).to eq(1)
        expect(subject[0].vbms_id).to eq("123456789")
      end
    end

    context "when passed an invalid vbms id" do
      context "length greater than 9" do
        let(:vbms_id) { "1234567890" }

        it "raises ActiveRecord::RecordNotFound error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "length less than 3" do
        let(:vbms_id) { "12" }

        it "raises ActiveRecord::RecordNotFound error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  context "#sanitize_and_validate_vbms_id" do
    subject { Appeal.sanitize_and_validate_vbms_id(vbms_id) }

    context "when passed a vbms id with a valid ssn" do
      let(:vbms_id) { "123456789" }
      it { is_expected.to eq("123456789S") }
    end

    context "when passed a vbms id with a valid ssn and appended alphabets" do
      let(:vbms_id) { "123456789S" }
      it { is_expected.to eq("123456789S") }
    end

    context "when passed a vbms id with a less than 9 digits" do
      let(:vbms_id) { "1234567" }
      it { is_expected.to eq("1234567C") }
    end

    context "when passed a vbms id less than 9 digits with leading zeros" do
      let(:vbms_id) { "0012347" }
      it { is_expected.to eq("12347C") }
    end

    context "when passed a vbms id less than 9 digits with leading zeros and alphabets" do
      let(:vbms_id) { "00123C00S9S" }
      it { is_expected.to eq("123009C") }
    end

    context "invalid vbms id" do
      context "when passed a vbms_id greater than 9 digits" do
        let(:vbms_id) { "1234567890" }

        it "raises RecordNotFound error" do
          expect { subject }.to raise_error(Caseflow::Error::InvalidVBMSId)
        end
      end

      context "when passed a vbms_id less than 3 digits" do
        let(:vbms_id) { "12" }

        it "raises RecordNotFound error" do
          expect { subject }.to raise_error(Caseflow::Error::InvalidVBMSId)
        end
      end

      context "when passed no vbms id" do
        let(:vbms_id) { "" }

        it "raises RecordNotFound error" do
          expect { subject }.to raise_error(Caseflow::Error::InvalidVBMSId)
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
    end

    context "for a file number with more than 9 digits" do
      let(:file_number) { "1234567890" }

      it "raises InvalidFileNumber error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidFileNumber)
      end
    end
  end

  context "#partial_grant?" do
    let(:appeal) { Generators::Appeal.build(vacols_id: "123", status: "Remand", issues: issues) }
    subject { appeal.partial_grant? }

    context "when no allowed issues" do
      let(:issues) { [Generators::Issue.build(disposition: :remanded)] }

      it { is_expected.to be_falsey }
    end

    context "when the allowed issues are new material" do
      let(:issues) { [Generators::Issue.build(disposition: :allowed, category: :new_material)] }

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

  context "#full_grant?" do
    let(:issues) { [] }
    let(:appeal) do
      Generators::Appeal.build(vacols_id: "123", status: status, issues: issues)
    end
    subject { appeal.full_grant? }

    context "when status is Remand" do
      let(:status) { "Remand" }
      it { is_expected.to be_falsey }
    end

    context "when status is Complete" do
      let(:status) { "Complete" }

      context "when at least one issues is new-material allowed" do
        let(:issues) do
          [
            Generators::Issue.build(disposition: :allowed, category: :new_material),
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

  context "#remand?" do
    subject { appeal.remand? }
    context "is false if status is not remand" do
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", status: "Complete") }
      it { is_expected.to be_falsey }
    end

    context "is true if status is remand" do
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", status: "Remand") }
      it { is_expected.to be_truthy }
    end

    context "is true if new-material allowed issue" do
      let(:issues) do
        [
          Generators::Issue.build(disposition: :allowed, category: :new_material),
          Generators::Issue.build(disposition: :remanded)
        ]
      end
      let(:appeal) { Generators::Appeal.build(vacols_id: "123", status: "Remand", issues: issues) }
      it { is_expected.to be_truthy }
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

  context "#decision_type" do
    subject { appeal.decision_type }
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
      let(:regional_office_key) { "ROXX" }
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

    before do
      BGSService.end_product_data = [
        {
          claim_receive_date: twenty_days_ago,
          claim_type_code: "172GRANT",
          status_type_code: "PEND"
        },
        {
          claim_receive_date: yesterday,
          claim_type_code: "170RMD",
          status_type_code: "CLR"
        },
        {
          claim_receive_date: yesterday,
          claim_type_code: "172BVAG",
          status_type_code: "CAN"
        },
        {
          claim_receive_date: last_year,
          claim_type_code: "172BVAG",
          status_type_code: "CLR"
        }
      ]
    end

    it "returns correct eps" do
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

    before do
      BGSService.end_product_data = [
        {
          claim_receive_date: twenty_days_ago,
          claim_type_code: "070BVAGR",
          end_product_type_code: "071",
          status_type_code: "PEND"
        },
        {
          claim_receive_date: last_year,
          claim_type_code: "070BVAGRARC",
          end_product_type_code: "070",
          status_type_code: "PEND"
        },
        {
          claim_receive_date: yesterday,
          claim_type_code: "070RMND",
          end_product_type_code: "072",
          status_type_code: "CAN"
        },
        {
          claim_receive_date: last_year,
          claim_type_code: "070RMNDARC",
          end_product_type_code: "072",
          status_type_code: "CLR"
        }
      ]
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

    let(:veteran_record) { { first_name: "Ed", last_name: "Merica" } }

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

    it "returns poa loaded with BGS values" do
      is_expected.to have_attributes(bgs_representative_type: "Attorney", bgs_representative_name: "Clarence Darrow")
    end

    context "#power_of_attorney.bgs_representative_address" do
      subject { appeal.power_of_attorney.bgs_representative_address }

      it "returns address if we are able to retrieve it" do
        is_expected.to include(
          address_line_1: "9999 MISSION ST",
          city: "SAN FRANCISCO",
          zip: "94103")
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
          cavc: true,
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

      let!(:issue_levels) do
        ["Other", "Left knee", "Right knee"]
      end

      let!(:issues) do
        [Generators::Issue.build(disposition: :allowed,
                                 program: :compensation,
                                 type: :elbow,
                                 category: :service_connection,
                                 levels: issue_levels
                                )
        ]
      end

      it "includes viewed boolean in hash" do
        expect(subject["viewed"]).to be_truthy
      end

      it "includes issues in hash" do
        expect(subject["issues"]).to eq(issues)
      end
    end
  end

  context ".for_api" do
    subject { Appeal.for_api(appellant_ssn: ssn) }

    let(:ssn) { "999887777" }

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
        )
      ]
    end

    it "returns filtered appeals for veteran sorted by latest event date" do
      expect(subject.length).to eq(2)
      expect(subject.first.form9_date).to eq(3.days.ago)
    end

    context "when ssn is nil" do
      let(:ssn) { nil }

      it "raises InvalidSSN error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidSSN)
      end
    end

    context "when ssn is less than 9 characters" do
      let(:ssn) { "99887777" }

      it "raises InvalidSSN error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidSSN)
      end
    end

    context "when SSN not found in BGS" do
      before do
        Fakes::BGSService.ssn_not_found = true
      end

      it "raises ActiveRecord::RecordNotFound error" do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
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
end
