describe Appeal do
  let(:yesterday) { 1.day.ago.to_formatted_s(:short_date) }
  let(:twenty_days_ago) { 20.days.ago.to_formatted_s(:short_date) }
  let(:last_year) { 365.days.ago.to_formatted_s(:short_date) }

  context "#documents_match?" do
    let(:nod_document) { Document.new(type: "NOD", received_at: 3.days.ago) }
    let(:soc_document) { Document.new(type: "SOC", received_at: 2.days.ago) }
    let(:form9_document) { Document.new(type: nil, alt_types: ["Form 9"], received_at: 1.day.ago) }

    let(:appeal) do
      Appeal.new(
        nod_date: 3.days.ago,
        soc_date: 2.days.ago,
        form9_date: 1.day.ago,
        documents: [nod_document, soc_document, form9_document]
      )
    end

    subject { appeal.documents_match? }

    context "when there is an nod, soc, and form9 document matching the respective dates" do
      it { is_expected.to be_truthy }

      context "and ssoc dates match" do
        before do
          appeal.documents += [
            Document.new(type: "SSOC", received_at: 6.days.ago),
            Document.new(type: "SSOC", received_at: 7.days.ago),
            Document.new(type: "SSOC", received_at: 9.days.ago)
          ]
          appeal.ssoc_dates = [6.days.ago, 7.days.ago]
        end

        it { is_expected.to be_truthy }
      end
    end

    context "when the nod date is mismatched" do
      before { nod_document.received_at = 5.days.ago }
      it { is_expected.to be_falsy }
    end

    context "when the soc date is mismatched" do
      before { soc_document.received_at = 5.days.ago }
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

      context "when document doesn't exist in the database" do
        it "should return documents saved in the database" do
          expect(result.first).to be_persisted
        end
      end
    end
  end

  context ".find_or_create_by_vacols_id" do
    before do
      allow(Appeal.repository).to receive(:load_vacols_data).and_return(nil)
    end

    subject { Appeal.find_or_create_by_vacols_id("123C") }

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
      before { @form8 = Form8.create(vacols_id: "765") }

      it "certifies the appeal using AppealRepository" do
        expect { subject }.to_not raise_error
        expect(Fakes::AppealRepository.certified_appeal).to eq(appeal)
      end

      it "uploads the correct form 8 using AppealRepository" do
        expect { subject }.to_not raise_error
        expect(Fakes::AppealRepository.uploaded_form8.id).to eq(@form8.id)
        expect(Fakes::AppealRepository.uploaded_form8_appeal).to eq(appeal)
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

  context "#partial_grant?" do
    subject { appeal.partial_grant? }
    context "is false" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Complete", disposition: "Allowed") }
      it { is_expected.to be_falsey }
    end

    context "is true" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Remand", disposition: "Allowed") }
      it { is_expected.to be_truthy }
    end
  end

  context "#full_grant?" do
    subject { appeal.full_grant? }
    context "is false" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Remand") }
      it { is_expected.to be_falsey }
    end

    context "is true" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Complete") }
      it { is_expected.to be_truthy }
    end
  end

  context "#remand?" do
    subject { appeal.remand? }
    context "is false" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Complete") }
      it { is_expected.to be_falsey }
    end

    context "is true" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Remand", disposition: "Remanded") }
      it { is_expected.to be_truthy }
    end
  end

  context "#decision_type" do
    subject { appeal.decision_type }
    context "is a full grant" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Remand", disposition: "Allowed") }
      it { is_expected.to eq("Partial Grant") }
    end

    context "is a partial grant" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Complete") }
      it { is_expected.to eq("Full Grant") }
    end

    context "is a remand" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Remand", disposition: "Remanded") }
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
    let(:decision) do
      Document.new(
        received_at: Time.zone.now.to_date,
        type: "BVA Decision"
      )
    end
    let(:old_decision) do
      Document.new(
        received_at: 5.days.ago.to_date,
        type: "BVA Decision"
      )
    end
    let(:appeal) do
      Appeal.new(
        vbms_id: "123"
      )
    end

    subject { appeal.decisions }
    context "returns single decision when only one decision" do
      before do
        appeal.documents = [decision]
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([decision]) }
    end

    context "returns single decision when only one valid" do
      before do
        appeal.documents = [decision, old_decision]
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([decision]) }
    end

    context "returns nil when no valid decision" do
      before do
        appeal.documents = [old_decision]
        appeal.decision_date = Time.current
      end

      it { is_expected.to eq([]) }
    end

    context "returns nil when no decision_date" do
      before do
        appeal.decision_date = nil
      end

      it { is_expected.to eq([]) }
    end

    context "returns multiple decisions when there are two decisions" do
      let(:documents) { [decision, decision.clone] }

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
          claim_type_code: "172GRANT",
          end_product_type_code: "172",
          status_type_code: "PEND"
        },
        {
          claim_receive_date: last_year,
          claim_type_code: "170RMD",
          end_product_type_code: "170",
          status_type_code: "PEND"
        },
        {
          claim_receive_date: yesterday,
          claim_type_code: "172BVAG",
          end_product_type_code: "172",
          status_type_code: "CAN"
        },
        {
          claim_receive_date: last_year,
          claim_type_code: "172BVAG",
          end_product_type_code: "172",
          status_type_code: "CLR"
        }
      ]
    end

    let(:result) { appeal.pending_eps }

    it "returns only pending eps" do
      expect(result.length).to eq(2)

      expect(result.first.claim_type_code).to eq("172GRANT")
      expect(result.last.claim_type_code).to eq("170RMD")
    end
  end

  context "#special_issues" do
    subject { appeal.special_issues }
    let(:appeal) { Appeal.new }

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
end
