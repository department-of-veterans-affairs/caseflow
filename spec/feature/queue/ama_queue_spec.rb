require "rails_helper"

RSpec.feature "AmaQueue" do
  before do
    Time.zone = "America/New_York"

    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_beaam_appeals)
    FeatureToggle.enable!(:test_facols)
  end
  after do
    FeatureToggle.disable!(:test_facols)
    FeatureToggle.disable!(:queue_beaam_appeals)
  end

  let(:attorney_first_name) { "Robby" }
  let(:attorney_last_name) { "McDobby" }
  let!(:attorney_user) do
    FactoryBot.create(:user, roles: ["Reader"], full_name: "#{attorney_first_name} #{attorney_last_name}")
  end

  let(:judge_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }

  let!(:vacols_atty) do
    FactoryBot.create(
      :staff,
      :attorney_role,
      sdomainid: attorney_user.css_id,
      snamef: attorney_first_name,
      snamel: attorney_last_name
    )
  end

  let!(:user) do
    User.authenticate!(user: attorney_user)
  end

  context "loads appellant detail view" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids).and_return(
        appeals.first.claimants.first.participant_id => {
          representative_name: poa_name,
          representative_type: "POA Attorney",
          participant_id: participant_id
        }
      )
    end

    let(:poa_address) { "123 Poplar St." }
    let(:participant_id) { "600153863" }
    let!(:root_task) { create(:root_task) }
    let!(:parent_task) { create(:ama_judge_task, assigned_to: judge_user, appeal: appeals.first, parent: root_task) }

    let(:poa_name) { "Test POA" }
    let(:veteran_participant_id) { "600085544" }
    let!(:appeals) do
      [
        create(
          :appeal,
          :advanced_on_docket,
          veteran: create(
            :veteran,
            participant_id: veteran_participant_id,
            first_name: "Pal",
            bgs_veteran_record: { first_name: "Pal" }
          ),
          documents: create_list(:document, 5),
          request_issues: build_list(:request_issue, 3, description: "Knee pain")
        ),
        create(
          :appeal,
          veteran: create(:veteran),
          documents: create_list(:document, 4),
          request_issues: build_list(:request_issue, 2, description: "PTSD")
        ),
        create(
          :appeal,
          number_of_claimants: 1,
          veteran: create(:veteran),
          documents: create_list(:document, 3),
          request_issues: build_list(:request_issue, 1, description: "Tinnitus")
        )
      ]
    end

    context "when appeals have tasks" do
      let!(:attorney_tasks) do
        [
          create(
            :ama_attorney_task,
            :in_progress,
            assigned_to: attorney_user,
            assigned_by: judge_user,
            parent: parent_task,
            appeal: appeals.first
          ),
          create(
            :ama_attorney_task,
            :in_progress,
            assigned_to: attorney_user,
            assigned_by: judge_user,
            appeal: appeals.second
          ),
          create(
            :ama_attorney_task,
            :in_progress,
            assigned_to: attorney_user,
            assigned_by: judge_user,
            appeal: appeals.third
          )
        ]
      end

      before do
        allow_any_instance_of(Fakes::BGSService).to receive(:find_address_by_participant_id).and_return(
          address_line_1: "Veteran Address",
          city: "Washington",
          state: "DC",
          zip: "20001"
        )
        allow_any_instance_of(Fakes::BGSService).to receive(:find_address_by_participant_id)
          .with(participant_id).and_return(
            address_line_1: poa_address,
            city: "Washington",
            state: "DC",
            zip: "20001"
          )
      end

      scenario "veteran is the appellant" do
        visit "/queue"

        click_on appeals.first.veteran.first_name
        expect(page).to have_content("A. Judge")

        expect(page).to have_content("About the Veteran")

        expect(page).to have_content("AOD")
        expect(page).to have_content(appeals.first.request_issues.first.description)
        expect(page).to have_content(appeals.first.docket_number)
        expect(page).to have_content(poa_name)
        expect(page).to have_content(poa_address)

        expect(page).to have_content("View Veteran's documents")
        expect(page).to have_selector("text", id: "NEW")
        expect(page).to have_content("5 docs")

        click_on "View Veteran's documents"
        expect(page).to have_content("Claims Folder")

        visit "/queue"
        click_on appeals.first.veteran.first_name

        expect(page).not_to have_selector("text", id: "NEW")
      end

      scenario "setting aod", focus: true do
        visit "/queue/appeals/#{appeals.first.external_id}"

        click_on "Edit AOD"

        find(".Select-control", text: "Select grant or deny").click
        find("div", class: "Select-option", text: "Grant").click

        find(".Select-control", text: "Select a type").click
        find("div", class: "Select-option", text: "Serious illness").click

        click_on "Submit"

        expect(page).to have_content("Advanced on docket motion")
        expect(page).to have_content("AOD")
        motion = appeals.first.claimants.first.advance_on_docket_motions.first

        expect(motion.granted).to eq(true)
        expect(motion.reason).to eq("Serious illness")
      end

      context "when there is an error loading addresses" do
        before do
          allow_any_instance_of(Fakes::BGSService).to receive(:find_address_by_participant_id)
            .with(participant_id).and_raise(StandardError.new)
        end

        scenario "loading data error message appears" do
          visit "/queue/appeals/#{appeals.first.external_id}"

          expect(page).to have_content(COPY::CASE_DETAILS_UNABLE_TO_LOAD)
        end
      end
    end

    context "when user is a vso" do
      let!(:user) do
        User.authenticate!(user: create(:user, roles: ["VSO"]))
      end

      let!(:appeals) do
        [
          create(:appeal, veteran: veteran, claimants: [build(:claimant, participant_id: participant_id)]),
          create(:appeal, veteran: veteran, claimants: [build(:claimant, participant_id: participant_id_without_vso)])
        ]
      end

      let(:veteran) { create(:veteran, file_number: "44556677") }

      let(:participant_id) { "1234" }
      let(:participant_id_without_vso) { "5678" }
      let(:vso_participant_id) { "2452383" }
      let(:participant_ids) { [participant_id, participant_id_without_vso] }
      let(:url) { "vietnam-veterans" }

      let!(:vso) do
        Vso.create(
          participant_id: vso_participant_id,
          url: url
        )
      end

      let(:vso_participant_ids) do
        [
          {
            representative_name: "VIETNAM VETERANS OF AMERICA",
            representative_type: "POA National Organization",
            participant_id: vso_participant_id
          },
          {
            representative_name: "PARALYZED VETERANS OF AMERICA, INC.",
            representative_type: "POA National Organization",
            participant_id: "2452383"
          }
        ]
      end

      let(:poas) do
        {
          participant_id => {
            representative_name: "PARALYZED VETERANS OF AMERICA, INC.",
            representative_type: "POA National Organization",
            participant_id: vso_participant_id
          },
          participant_id_without_vso => {}
        }
      end

      before do
        allow_any_instance_of(BGSService).to receive(:get_participant_id_for_user).and_return(participant_id)
        allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_id).and_return(vso_participant_ids)
        allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids).and_return(poas)
      end

      scenario "when searching for cases" do
        visit "/organizations/#{url}"

        fill_in "searchBar", with: veteran.file_number
        click_on "Search"

        expect(page).to have_content(appeals.first.docket_number)
        expect(page).to_not have_content(appeals.second.docket_number)
      end
    end
  end
end
