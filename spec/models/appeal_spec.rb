describe Appeal do
  context "#documents_match?" do
    let(:nod_document) { Document.new(type: :nod, received_at: 3.days.ago) }
    let(:soc_document) { Document.new(type: :soc, received_at: 2.days.ago) }
    let(:form9_document) { Document.new(type: :form9, received_at: 1.day.ago) }

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
            Document.new(type: :ssoc, received_at: 6.days.ago),
            Document.new(type: :ssoc, received_at: 7.days.ago),
            Document.new(type: :ssoc, received_at: 9.days.ago)
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
          Document.new(type: :ssoc, received_at: 6.days.ago),
          Document.new(type: :ssoc, received_at: 7.days.ago)
        ]

        appeal.ssoc_dates = [6.days.ago, 9.days.ago]
      end

      it { is_expected.to be_falsy }
    end
  end

  context ".normalize_vacols_date" do
    subject { Appeal.normalize_vacols_date(datetime) }

    context "when datetime is nil" do
      let(:datetime) { nil }
      it { is_expected.to be_nil }
    end

    context "when datetime is in a non-UTC timezone" do
      before { Time.zone = "America/Chicago" }
      let(:datetime) { Time.new(2013, 9, 5, 16, 0, 0, "-08:00") }
      it { is_expected.to eq(Time.zone.local(2013, 9, 6)) }
    end
  end

  context ".from_records" do
    before { Timecop.freeze }
    after { Timecop.return }

    let(:case_record) do
      OpenStruct.new(
        bfcorlid: "VBMS-ID",
        bfac: "4",
        bfso: "Q",
        bfpdnum: "INSURANCE-LOAN-NUMBER",
        bfdrodec: 11.days.ago,
        bfdnod: 10.days.ago,
        bfdsoc: 9.days.ago,
        bfd19: 8.days.ago,
        bfssoc1: 7.days.ago,
        bfssoc2: 6.days.ago,
        bfha: "6",
        bfregoff: "DSUSER"
      )
    end

    let(:correspondent_record) do
      OpenStruct.new(
        snamef: "Phil",
        snamemi: "J",
        snamel: "Johnston",
        sspare1: "Chris",
        sspare2: "M",
        sspare3: "Johnston",
        susrtyp: "Brother"
      )
    end

    let(:folder_record) do
      OpenStruct.new(
        tivbms: "Y"
      )
    end

    subject do
      Appeal.from_records(
        case_record: case_record,
        correspondent_record: correspondent_record,
        folder_record: folder_record
      )
    end

    it do
      is_expected.to have_attributes(
        vbms_id: "VBMS-ID",
        type: "Reconsideration",
        file_type: "VBMS",
        representative: "Catholic War Veterans",
        veteran_first_name: "Phil",
        veteran_middle_initial: "J",
        veteran_last_name: "Johnston",
        appellant_first_name: "Chris",
        appellant_middle_name: "M",
        appellant_last_name: "Johnston",
        appellant_relationship: "Brother",
        insurance_loan_number: "INSURANCE-LOAN-NUMBER",
        notification_date: Appeal.normalize_vacols_date(11.days.ago),
        nod_date: Appeal.normalize_vacols_date(10.days.ago),
        soc_date: Appeal.normalize_vacols_date(9.days.ago),
        form9_date: Appeal.normalize_vacols_date(8.days.ago),
        ssoc_dates: [
          Appeal.normalize_vacols_date(7.days.ago),
          Appeal.normalize_vacols_date(6.days.ago)
        ],
        hearing_type: :video_hearing,
        regional_office_key: "DSUSER"
      )
    end

    context "No appellant listed" do
      let(:correspondent_record) do
        OpenStruct.new(
          snamef: "Phil",
          snamemi: "J",
          snamel: "Johnston",
          susrtyp: "Brother"
        )
      end

      it { is_expected.to have_attributes(appellant_relationship: "") }
    end
  end

  context ".find" do
    class FakeRepo
      def self.find(_id)
        Appeal.new(representative: "Shane's VSO")
      end
    end

    before { Appeal.repository = FakeRepo }
    subject { Appeal.find("123C") }

    it "delegates to the repository" do
      expect(subject.representative).to eq("Shane's VSO")
    end

    it "sets the vacols_id" do
      expect(subject.vacols_id).to eq("123C")
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
end
