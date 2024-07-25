# frozen_string_literal: true

describe AojAppealRepository, :all_dbs do
  let(:correspondent_record) do
    OpenStruct.new(
      snamef: "Phil",
      snamemi: "J",
      snamel: "Johnston",
      sspare1: "Johnston",
      sspare2: "Chris",
      sspare3: "M",
      susrtyp: "Brother",
      sfnod: 100.days.ago
    )
  end

  let(:folder_record) do
    OpenStruct.new(
      tivbms: "Y",
      tinum: "13 11-265",
      tiread2: "2012091234"
    )
  end

  let(:case_record) do
    OpenStruct.new(
      bfkey: "123C",
      bfcorlid: "VBMS-ID",
      bfac: "3",
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
      bfddec: 1.day.ago,
      correspondent: correspondent_record,
      folder: folder_record,
      case_issues: [{
        issdesc: "Issue Description",
        issdc: "1",
        issprog: "Issue Program"
      }]
    )
  end

  context ".set_vacols_values" do
    before do
      Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
      allow_any_instance_of(LegacyAppeal).to receive(:check_and_load_vacols_data!).and_return(nil)
    end

    subject do
      appeal = LegacyAppeal.new
      AojAppealRepository.set_vacols_values(
        appeal: appeal,
        case_record: case_record
      )
    end

    it do
      is_expected.to have_attributes(
        vbms_id: "VBMS-ID",
        type: "Post Remand",
        file_type: "VBMS",
        veteran_first_name: "Phil",
        veteran_middle_initial: "J",
        veteran_last_name: "Johnston",
        appellant_first_name: "Chris",
        appellant_middle_initial: "M",
        appellant_last_name: "Johnston",
        appellant_relationship: "Brother",
        insurance_loan_number: "INSURANCE-LOAN-NUMBER",
        notification_date: AojAppealRepository.normalize_vacols_date(11.days.ago),
        nod_date: AojAppealRepository.normalize_vacols_date(10.days.ago),
        soc_date: AojAppealRepository.normalize_vacols_date(9.days.ago),
        form9_date: AojAppealRepository.normalize_vacols_date(8.days.ago),
        ssoc_dates: [
          AojAppealRepository.normalize_vacols_date(7.days.ago),
          AojAppealRepository.normalize_vacols_date(6.days.ago)
        ],
        notice_of_death_date: AojAppealRepository.normalize_vacols_date(100.days.ago),
        hearing_request_type: :central_office,
        hearing_requested: true,
        hearing_held: true,
        regional_office_key: "DSUSER",
        disposition: "Withdrawn",
        decision_date: AojAppealRepository.normalize_vacols_date(1.day.ago),
        docket_number: "13 11-265",
        citation_number: "2012091234"
      )
    end
  end
end
