# frozen_string_literal: true

describe "SearchQueryService" do
  let(:ssn) { "146600001" }
  let(:dob) { Faker::Date.in_date_period(year: 1960) }

  let(:uuid) { SecureRandom.uuid }
  let(:veteran_first_name) { Faker::Name.first_name }
  let(:veteran_last_name) { Faker::Name.last_name }
  let(:claimant_first_name) { Faker::Name.first_name }
  let(:claimant_last_name) { Faker::Name.last_name }
  let(:veteran_full_name) { FullName.new(veteran_first_name, "", veteran_last_name).to_s }
  let(:claimant_full_name) { FullName.new(claimant_first_name, "", claimant_last_name).to_s }
  let(:docket_type) { "hearing" }
  let(:docket_number) { "240111-1111" }

  let(:descision_document_attrs) do
    {
      decision_date: Faker::Date.between(from: 2.years.ago, to: 1.year.ago)
    }
  end

  context "all data in caseflow" do
    context "veteran is claimant" do
      let(:veteran_attrs) do
        {
          ssn: ssn,
          file_number: ssn,
          date_of_birth: dob,
          date_of_death: nil,
          first_name: veteran_first_name,
          middle_name: nil,
          last_name: veteran_last_name
        }
      end

      let(:veteran) { FactoryBot.create(:veteran, veteran_attrs) }

      let(:appeal_attributes) do
        {
          aod_based_on_age: false,
          stream_docket_number: docket_number,
          veteran_file_number: ssn,
          veteran: veteran,
          stream_type: Constants.AMA_STREAM_TYPES.original,
          uuid: uuid
        }
      end

      let(:judge) { create(:user, :judge) }

      let!(:appeal) do
        FactoryBot.create(
          :appeal,
          # has hearing(s)
          :hearing_docket,
          :held_hearing,
          :tied_to_judge,
          # has decision document
          :dispatched,
          # has issue(s)
          :with_request_issues,
          :with_decision_issue,
          {
            associated_judge: judge,
            tied_judge: judge
          }.merge(appeal_attributes)
        ).tap do |appeal|
          appeal.decision_issues.first.update(
            mst_status: true,
            pact_status: true
          )
          appeal.hearings.first.update(updated_by: judge)
          # create work mode
          appeal.overtime = true
          AdvanceOnDocketMotion.create(
            person: appeal.claimants.first.person,
            appeal: appeal
          )
        end.reload
      end

      context "finds by docket number" do
        subject { SearchQueryService.new(docket_number: appeal.stream_docket_number) }

        it "finds by docket number" do
          expect(appeal).to be_persisted

          search_results = subject.search_by_docket_number

          expect(search_results.length).to eq(1)

          result = search_results.first.api_response

          expect(result.id).to be
          expect(result.type).to eq "appeal"

          attributes = result.attributes

          expect(attributes.aod).to be_truthy
          expect(attributes.appellant_full_name).to eq veteran_full_name
          expect(attributes.assigned_to_location).to eq appeal.assigned_to_location
          expect(attributes.caseflow_veteran_id).to eq veteran.id
          expect(attributes.decision_date).to eq appeal.decision_document.decision_date
          expect(attributes.docket_name).to eq appeal.docket_type
          expect(attributes.docket_number).to eq appeal.stream_docket_number
          expect(attributes.external_id).to eq appeal.uuid
          expect(attributes.hearings.length).to eq appeal.hearings.length
          expect(attributes.issues.length).to eq(appeal.request_issues.length)
          expect(attributes.mst).to eq appeal.decision_issues.any?(&:mst_status)
          expect(attributes.pact).to eq appeal.decision_issues.any?(&:pact_status)
          expect(attributes.paper_case).to be_falsy
          expect(attributes.status).to eq Appeal.find(appeal.id).status.status
          expect(attributes.veteran_appellant_deceased).to be_falsy
          expect(attributes.veteran_file_number).to eq ssn
          expect(attributes.veteran_full_name).to eq veteran_full_name
          expect(attributes.contested_claim).to be_falsy
          expect(attributes.withdrawn).to eq(false)
        end
      end

      context "finds by file number" do
        subject { SearchQueryService.new(file_number: ssn) }

        it "finds by veteran file number" do
          expect(appeal).to be_persisted

          search_results = subject.search_by_veteran_file_number

          expect(search_results.length).to eq(1)

          result = search_results.first.api_response

          expect(result.id).to be
          expect(result.type).to eq "appeal"
        end
      end

      context "finds by veteran ids" do
        subject { SearchQueryService.new(veteran_ids: [veteran.id]) }

        it "finds by veteran ids" do
          expect(appeal).to be_persisted

          search_results = subject.search_by_veteran_ids

          expect(search_results.length).to eq(1)

          result = search_results.first.api_response

          expect(result.id).to be
          expect(result.type).to eq "appeal"
        end
      end
    end
  end

  let(:veteran_address) do
    {
      addrs_one_txt: nil,
      addrs_two_txt: nil,
      addrs_three_txt: nil,
      city_nm: nil,
      cntry_nm: nil,
      postal_cd: nil,
      zip_prefix_nbr: nil,
      ptcpnt_addrs_type_nm: nil
    }
  end

  let(:legacy_appeal) do
    create(
      :legacy_appeal,
      vbms_id: ssn,
      vacols_case: vacols_case,
      veteran_address: veteran_address
    )
  end

  # must be created first for legacy_appeal factory to find it
  let!(:veteran) do
    create(
      :veteran,
      file_number: ssn,
      first_name: veteran_first_name,
      last_name: veteran_last_name
    )
  end

  let(:vacols_decision_date) { 2.weeks.ago }
  let(:vacols_case_attrs) do
    {
      bfkey: ssn,
      bfcorkey: ssn,
      bfac: "1",
      bfcorlid: "100000099",
      bfcurloc: "CASEFLOW",
      bfddec: vacols_decision_date,
      bfmpro: "ACT"

      # bfregoff: "RO18",
      # bfdloout: "2024-03-26T11:13:32.000Z",
      # bfcallup: "",
      # bfhr: "2",
      # bfdocind: "T",
    }
  end

  let(:issues_count) { 5 }
  let(:vacols_case_issues) do
    create_list(
      :case_issue,
      issues_count,
      isspact: "Y",
      issmst: "Y"
    )
  end

  let(:hearings_count) { 5 }
  let(:vacols_case_hearings) do
    create_list(
      :case_hearing,
      hearings_count
    )
  end

  let(:vacols_correspondent) do
    create(:correspondent, vacols_correspondent_attrs)
  end

  let(:vacols_folder) do
    build(:folder)
  end

  let(:vacols_case) do
    create(
      :case,
      {
        correspondent: vacols_correspondent,
        case_issues: vacols_case_issues,
        case_hearings: vacols_case_hearings,
        folder: vacols_folder
      }.merge(vacols_case_attrs)
    )
  end

  context "when appeal is a legacy appeal with data in vacols and caseflow" do
    context "when veteran is claimant" do
      let(:vacols_correspondent_attrs) do
        {
          sspare2: veteran_first_name,
          sspare1: veteran_last_name,
          snamel: veteran_last_name,
          snamef: veteran_first_name,
          stafkey: ssn
        }
      end

      let!(:claimant) do
        create(
          :claimant,
          type: "VeteranClaimant",
          decision_review: legacy_appeal
        )
      end

      subject { SearchQueryService.new(file_number: ssn) }

      it "finds by file number" do
        search_results = subject.search_by_veteran_file_number
        result = search_results.first.api_response

        expect(result.id).to be
        expect(result.type).to eq "legacy_appeal"

        attributes = result.attributes
        expect(attributes.docket_name).to eq "legacy"
        expect(attributes.aod).to be_falsy
        expect(attributes.appellant_full_name).to eq veteran_full_name
        expect(attributes.assigned_to_location).to eq legacy_appeal.assigned_to_location
        expect(attributes.caseflow_veteran_id).to eq veteran.id
        expect(attributes.decision_date).to eq AppealRepository.normalize_vacols_date(vacols_decision_date)
        expect(attributes.docket_name).to eq "legacy"
        expect(attributes.docket_number).to eq vacols_folder.tinum
        expect(attributes.external_id).to eq vacols_case.id
        expect(attributes.hearings.length).to eq hearings_count
        expect(attributes.issues.length).to eq issues_count
        expect(attributes.mst).to be_truthy
        expect(attributes.pact).to be_truthy
        expect(attributes.paper_case).to eq "Paper"
        expect(attributes.status).to eq "Active"
        expect(attributes.veteran_appellant_deceased).to be_falsy
        expect(attributes.veteran_file_number).to eq ssn
        expect(attributes.veteran_full_name).to eq veteran_full_name
        expect(attributes.withdrawn).to be_falsy
      end

      context "finds by veteran ids" do
        subject { SearchQueryService.new(veteran_ids: [veteran.id]) }

        it "finds by veteran ids" do
          search_results = subject.search_by_veteran_ids
          result = search_results.first.api_response

          expect(result.id).to be
          expect(result.type).to eq "legacy_appeal"
        end
      end
    end
  end
end
