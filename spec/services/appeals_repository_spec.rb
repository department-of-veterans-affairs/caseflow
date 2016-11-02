describe AppealRepository do
  before do
    @old_repo = Appeal.repository
    Appeal.repository = AppealRepository

    Appeal.any_instance.stub(:check_and_load_vacols_data!) {}
  end
  after { Appeal.repository = @old_repo }

  context ".normalize_vacols_date" do
    subject { AppealRepository.normalize_vacols_date(datetime) }

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

  context ".set_vacols_values" do
    before { Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0)) }
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
        bfhr: "1",
        bfregoff: "DSUSER",
        bfdc: "9",
        bfddec: 1.day.ago
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
      appeal = Appeal.new
      case_record.correspondent = correspondent_record
      case_record.folder = folder_record
      AppealRepository.set_vacols_values(
        appeal: appeal,
        case_record: case_record
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
        appellant_middle_initial: "M",
        appellant_last_name: "Johnston",
        appellant_relationship: "Brother",
        insurance_loan_number: "INSURANCE-LOAN-NUMBER",
        notification_date: AppealRepository.normalize_vacols_date(11.days.ago),
        nod_date: AppealRepository.normalize_vacols_date(10.days.ago),
        soc_date: AppealRepository.normalize_vacols_date(9.days.ago),
        form9_date: AppealRepository.normalize_vacols_date(8.days.ago),
        ssoc_dates: [
          AppealRepository.normalize_vacols_date(7.days.ago),
          AppealRepository.normalize_vacols_date(6.days.ago)
        ],
        hearing_type: :video_hearing,
        hearing_requested: true,
        hearing_held: true,
        regional_office_key: "DSUSER",
        disposition: "Withdrawn",
        decision_date: AppealRepository.normalize_vacols_date(1.day.ago)
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
end

