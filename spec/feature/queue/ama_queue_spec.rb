require "rails_helper"

RSpec.feature "AmaQueue" do
  before do
    Time.zone = "America/New_York"

    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_beaam_appeals)
  end
  after do
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

      scenario "setting aod" do
        visit "/queue/appeals/#{appeals.first.external_id}"

        click_on "Edit"

        find(".Select-control", text: "Select grant or deny").click
        find("div", class: "Select-option", text: "Grant").click

        find(".Select-control", text: "Select a type").click
        find("div", class: "Select-option", text: "Serious illness").click

        click_on "Submit"

        expect(page).to have_content("AOD status updated")
        expect(page).to have_content("AOD")
        motion = appeals.first.claimants.first.person.advance_on_docket_motions.first

        expect(motion.granted).to eq(true)
        expect(motion.reason).to eq("serious_illness")
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

    context "when user is part of translation" do
      let(:user_name) { "Translation User" }
      let(:other_user_name) { "Other User" }
      let!(:user) { User.authenticate!(user: create(:user, roles: ["Reader"], full_name: user_name)) }
      let!(:other_user) { create(:user, roles: ["Reader"], full_name: other_user_name) }
      let!(:translation_organization) { Organization.create!(name: "Translation", url: "translation") }
      let!(:other_organization) { Organization.create!(name: "Other organization", url: "other") }

      let!(:translation_task) do
        create(
          :generic_task,
          :in_progress,
          assigned_to: translation_organization,
          assigned_by: judge_user,
          parent: parent_task,
          appeal: appeals.first,
          instructions: [existing_instruction]
        )
      end

      let(:existing_instruction) { "Existing instruction" }
      let(:instructions) { "Test instructions" }

      before do
        OrganizationsUser.add_user_to_organization(user, translation_organization)
        OrganizationsUser.add_user_to_organization(other_user, translation_organization)
      end

      scenario "assign case to self", focus: true do
        visit "/organizations/#{translation_organization.url}"

        click_on "Pal Smith"

        find(".Select-control", text: "Select an action").click
        find("div", class: "Select-option", text: "Assign to person").click

        find(".Select-control", text: "Select a user").click
        find("div", class: "Select-option", text: other_user.full_name).click

        expect(page).to have_content(existing_instruction)
        click_on "Submit"

        expect(page).to have_content("Task assigned to #{other_user_name}")
        expect(translation_task.reload.status).to eq("on_hold")


        visit "/organizations/#{translation_organization.url}"
        click_on "Assigned"
        click_on "Pal Smith"


        find(".Select-control", text: "Select an action").click
        find("div", class: "Select-option", text: "Re-assign to person").click

        find(".Select-control", text: "Select a user").click
        find("div", class: "Select-option", text: user.full_name).click
        binding.pry

        expect(page).to have_content(existing_instruction)
        click_on "Submit"

        expect(page).to have_content("Task assigned to #{user_name}")
        expect(translation_task.reload.children.frist.status).to eq("completed")

        # On hold tasks should not be visible on the case details screen
        # expect(page).to_not have_content("Actions")

        click_on "Caseflow"

        click_on "Pal Smith"

        expect(page).to have_content(existing_instruction)

        find(".Select-control", text: "Select an action").click
        find("div", class: "Select-option", text: "Assign to team").click

        find(".Select-control", text: "Select a team").click
        find("div", class: "Select-option", text: other_organization.name).click
        fill_in "taskInstructions", with: instructions

        click_on "Submit"

        expect(page).to have_content("Task assigned to #{other_organization.name}")
        expect(Task.last.instructions.first).to eq(instructions)
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
        visit "/search"

        fill_in "searchBarEmptyList", with: veteran.file_number
        click_on "Search"

        expect(page).to have_content(appeals.first.docket_number)
        expect(page).to_not have_content(appeals.second.docket_number)
      end
    end
  end

  context "QR flow" do
    let(:user_name) { "QR User" }
    let!(:user) { FactoryBot.create(:user, roles: ["Reader"], full_name: user_name) }

    let(:judge_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }
    let!(:judge_staff) { FactoryBot.create(:staff, :judge_role, user: judge_user) }

    let!(:quality_review_organization) { QualityReview.singleton }
    let!(:other_organization) { Organization.create!(name: "Other organization", url: "other") }
    let!(:appeal) { create(:appeal) }

    let!(:quality_review_task) do
      create(
        :quality_review_task,
        :in_progress,
        assigned_to: quality_review_organization,
        assigned_by: judge_user,
        parent: root_task,
        appeal: appeal
      )
    end

    let!(:quality_review_instructions) { "Fix this case!" }
    let!(:root_task) { create(:root_task) }

    let!(:judge_task) { create(:ama_judge_task, parent: root_task, assigned_to: judge_user, status: :completed) }

    before do
      OrganizationsUser.add_user_to_organization(user, quality_review_organization)
      # We expect all QR users to be attorneys. This matters because we serve different queue views on the frontend
      # to attorneys.
      FactoryBot.create(:staff, user: user)
      User.authenticate!(user: user)
    end

    scenario "return case to judge" do
      visit "/organizations/#{quality_review_organization.url}"
      click_on "Bob Smith"

      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: "Assign to person").click

      find(".Select-control", text: "Select a user").click
      find("div", class: "Select-option", text: user.full_name).click

      fill_in "taskInstructions", with: "Review the quality"
      click_on "Submit"

      expect(page).to have_content("Task assigned to #{user_name}")

      click_on "Caseflow"

      click_on "Bob Smith"

      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: "Return to judge").click

      fill_in "taskInstructions", with: quality_review_instructions

      click_on "Submit"
      expect(page).to have_content("You have no cases assigned")

      User.authenticate!(user: judge_user)

      visit "/queue"

      click_on "Switch to Assign Cases"
      click_on "Bob Smith"

      expect(page).to have_content(quality_review_instructions)
    end
  end
end
