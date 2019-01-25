require "rails_helper"

RSpec.feature "AmaQueue" do
  context "loads appellant detail view" do
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

    before do
      Time.zone = "America/New_York"

      Fakes::Initializer.load!
      FeatureToggle.enable!(:queue_beaam_appeals)

      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids).and_return(
        appeals.first.claimants.first.participant_id => {
          representative_name: poa_name,
          representative_type: "POA Attorney",
          participant_id: participant_id
        }
      )
    end

    after do
      FeatureToggle.disable!(:queue_beaam_appeals)
    end

    let(:poa_address) { "123 Poplar St." }
    let(:participant_id) { "600153863" }
    let!(:root_task) { FactoryBot.create(:root_task) }
    let!(:parent_task) do
      FactoryBot.create(:ama_judge_task, assigned_to: judge_user, appeal: appeals.first, parent: root_task)
    end

    let(:poa_name) { "Test POA" }
    let(:veteran_participant_id) { "600085544" }
    let(:file_numbers) { Array.new(3) { Random.rand(999_999_999).to_s } }
    let!(:appeals) do
      [
        FactoryBot.create(
          :appeal,
          :advanced_on_docket_due_to_age,
          veteran: FactoryBot.create(
            :veteran,
            participant_id: veteran_participant_id,
            first_name: "Pal",
            bgs_veteran_record: { first_name: "Pal" },
            file_number: file_numbers[0]
          ),
          documents: FactoryBot.create_list(:document, 5, file_number: file_numbers[0]),
          request_issues: build_list(:request_issue, 3, contested_issue_description: "Knee pain")
        ),
        FactoryBot.create(
          :appeal,
          veteran: FactoryBot.create(:veteran, file_number: file_numbers[1]),
          documents: FactoryBot.create_list(:document, 4, file_number: file_numbers[1]),
          request_issues: build_list(:request_issue, 2, contested_issue_description: "PTSD")
        ),
        FactoryBot.create(
          :appeal,
          number_of_claimants: 1,
          veteran: FactoryBot.create(:veteran, file_number: file_numbers[2]),
          documents: FactoryBot.create_list(:document, 3, file_number: file_numbers[2]),
          request_issues: build_list(:request_issue, 1, contested_issue_description: "Tinnitus")
        )
      ]
    end

    context "when appeals have tasks" do
      let!(:attorney_tasks) do
        [
          FactoryBot.create(
            :ama_attorney_task,
            :in_progress,
            assigned_to: attorney_user,
            assigned_by: judge_user,
            parent: parent_task,
            appeal: appeals.first
          ),
          FactoryBot.create(
            :ama_attorney_task,
            :in_progress,
            assigned_to: attorney_user,
            assigned_by: judge_user,
            appeal: appeals.second
          ),
          FactoryBot.create(
            :ama_attorney_task,
            :in_progress,
            assigned_to: attorney_user,
            assigned_by: judge_user,
            appeal: appeals.third
          )
        ]
      end

      before do
        allow_any_instance_of(AodTeam).to receive(:user_has_access?).with(attorney_user).and_return(true)
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

        expect(page.text).to match(/View (\d+) docs/)
        expect(page).to have_selector("text", id: "NEW")
        expect(page).to have_content("5 docs")

        find("a", text: /View (\d+) docs/).click
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
      let!(:user) { User.authenticate!(user: FactoryBot.create(:user, roles: ["Reader"], full_name: user_name)) }
      let!(:other_user) { FactoryBot.create(:user, roles: ["Reader"], full_name: other_user_name) }
      let!(:translation_organization) { Translation.singleton }
      let!(:other_organization) { Organization.create!(name: "Other organization", url: "other") }

      let!(:translation_task) do
        FactoryBot.create(
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

      scenario "assign case to self" do
        visit translation_organization.path

        click_on "Pal Smith"

        find(".Select-control", text: "Select an action").click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h[:label]).click

        find(".Select-control", text: user.full_name).click
        find("div", class: "Select-option", text: other_user.full_name).click

        expect(page).to have_content(existing_instruction)
        click_on "Submit"

        expect(page).to have_content("Task assigned to #{other_user_name}")
        expect(translation_task.reload.status).to eq("on_hold")

        visit "/organizations/#{translation_organization.url}"
        click_on "Assigned"
        click_on "Pal Smith"

        find(".Select-control", text: "Select an action").click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h[:label]).click

        fill_in "taskInstructions", with: instructions
        click_on "Submit"

        expect(page).to have_content("Task reassigned to #{user_name}")
        old_task = translation_task.reload.children.find { |task| task.assigned_to == other_user }
        expect(old_task.status).to eq("completed")

        # On hold tasks should not be visible on the case details screen
        # expect(page).to_not have_content("Actions")

        click_on "Caseflow"

        click_on "Pal Smith"

        find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL, id: old_task.id.to_s).click
        expect(page).to have_content(existing_instruction)

        find(".Select-control", text: "Select an action").click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h[:label]).click

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
        User.authenticate!(user: FactoryBot.create(:user, roles: ["VSO"]))
      end

      let!(:appeals) do
        [
          FactoryBot.create(
            :appeal,
            veteran: veteran,
            claimants: [build(:claimant, participant_id: participant_id)]
          ),
          FactoryBot.create(
            :appeal,
            veteran: veteran,
            claimants: [build(:claimant, participant_id: participant_id_without_vso)]
          )
        ]
      end

      let(:veteran) { FactoryBot.create(:veteran, file_number: "44556677") }

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
    let(:veteran_first_name) { "Marissa" }
    let(:veteran_last_name) { "Vasquez" }
    let(:veteran_full_name) { "#{veteran_first_name} #{veteran_last_name}" }
    let!(:veteran) { FactoryBot.create(:veteran, first_name: veteran_first_name, last_name: veteran_last_name) }

    let(:qr_user_name) { "QR User" }
    let(:qr_user_name_short) { "Q. User" }
    let!(:qr_user) { FactoryBot.create(:user, roles: ["Reader"], full_name: qr_user_name) }

    let(:judge_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Javitz") }
    let!(:judge_staff) { FactoryBot.create(:staff, :judge_role, user: judge_user) }

    let(:attorney_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Nicole Apple") }
    let!(:attorney_staff) { FactoryBot.create(:staff, :attorney_role, user: attorney_user) }

    let!(:quality_review_organization) { QualityReview.singleton }
    let!(:other_organization) { Organization.create!(name: "Other organization", url: "other") }
    let!(:appeal) { FactoryBot.create(:appeal, veteran_file_number: veteran.file_number) }

    let!(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let!(:judge_task) do
      FactoryBot.create(:ama_judge_task, appeal: appeal, parent: root_task, assigned_to: judge_user, status: :completed)
    end
    let!(:qr_task) do
      FactoryBot.create(
        :qr_task,
        :in_progress,
        assigned_to: quality_review_organization,
        assigned_by: judge_user,
        parent: root_task,
        appeal: appeal
      )
    end

    let!(:qr_instructions) { "Fix this case!" }

    before do
      ["Reba Janowiec", "Lee Jiang", "Pearl Jurs"].each do |judge_name|
        FactoryBot.create(
          :staff,
          :judge_role,
          user: FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: judge_name)
        )
      end

      OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), BvaDispatch.singleton)

      FactoryBot.create(:staff, user: qr_user)
      OrganizationsUser.add_user_to_organization(qr_user, quality_review_organization)
      User.authenticate!(user: qr_user)
    end

    scenario "return case to judge" do
      expect(QualityReviewTask.count).to eq 1
      # step "QR user visits the quality review organization page and assigns the task to themself"
      visit quality_review_organization.path
      click_on veteran_full_name

      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h[:label]).click

      fill_in "taskInstructions", with: "Review the quality"
      click_on "Submit"

      expect(page).to have_content("Task assigned to #{qr_user_name}")

      expect(QualityReviewTask.count).to eq 2

      # step "QR user returns the case to a judge"
      click_on "Caseflow"

      click_on veteran_full_name

      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.RETURN_TO_JUDGE.to_h[:label]).click

      expect(dropdown_selected_value(find(".cf-modal-body"))).to eq judge_user.full_name
      fill_in "taskInstructions", with: qr_instructions

      click_on "Submit"
      expect(page).to have_content("On hold (3)")

      # step "judge reviews case and assigns a task to an attorney"
      User.authenticate!(user: judge_user)

      visit "/queue"

      click_on veteran_full_name

      find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL, match: :first).click

      expect(page).to have_content(qr_instructions)

      find(".Select-control", text: "Select an action", match: :first).click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h[:label]).click

      find(".Select-control", text: "Select a user").click
      find("div", class: "Select-option", text: "Other").click

      find(".Select-control", text: "Select a user").click
      first("div", class: "Select-option", text: attorney_user.full_name).click
      click_on "Submit"

      expect(page).to have_content("Assigned 1 case")

      # step "attorney completes task and returns the case to the judge"
      User.authenticate!(user: attorney_user)

      visit "/queue"

      click_on veteran_full_name

      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.REVIEW_DECISION.to_h[:label]).click

      expect(page).to have_content("Select special issues (optional)")

      click_on "Continue"

      expect(page).to have_content("Select Dispositions")

      click_on "Continue"

      expect(page).to have_content("Submit Draft Decision for Review")

      fill_in "Document ID:", with: "1234"
      click_on "Select a judge"
      find(".Select-control", text: "Select a judge…").click
      first("div", class: "Select-option", text: judge_user.full_name).click
      fill_in "notes", with: "all done"

      click_on "Continue"

      expect(page).to have_content(
        "Thank you for drafting #{veteran_full_name}'s decision. It's been sent to #{judge_user.full_name} for review."
      )

      # step "judge completes task"
      User.authenticate!(user: judge_user)

      visit "/queue"

      click_on veteran_full_name

      find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL, match: :first).click
      expect(page).to have_content(qr_instructions)

      find(".Select-control", text: "Select an action", match: :first).click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.to_h[:label]).click

      expect(page).to have_content("Mark this task \"complete\" and send the case back to #{qr_user_name_short}")

      click_on "Mark complete"

      expect(page).to have_content("#{veteran_full_name}'s case has been marked complete")

      # step "QR reviews case"
      User.authenticate!(user: qr_user)

      visit "/queue"

      click_on veteran_full_name

      expect(page).to have_content(COPY::CASE_TIMELINE_ATTORNEY_TASK)
      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.to_h[:label]).click

      expect(page).to have_content("Mark this task \"complete\" and send the case back to #{qr_user_name_short}")

      click_on "Mark complete"

      expect(page).to have_content("#{veteran_full_name}'s case has been marked complete")
    end
  end

  context "Judge has a case to assign to an attorney" do
    let(:veteran_first_name) { "Monica" }
    let(:veteran_last_name) { "Valencia" }
    let(:veteran_full_name) { "#{veteran_first_name} #{veteran_last_name}" }
    let!(:veteran) { FactoryBot.create(:veteran, first_name: veteran_first_name, last_name: veteran_last_name) }

    let(:judge_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Anna Juarez") }
    let!(:judge_staff) { FactoryBot.create(:staff, :judge_role, user: judge_user) }
    let!(:judgeteam) { JudgeTeam.create_for_judge(judge_user) }

    let(:attorney_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Steven Ahr") }
    let!(:attorney_staff) { FactoryBot.create(:staff, :attorney_role, user: attorney_user) }

    let!(:appeal) do
      FactoryBot.create(
        :appeal,
        veteran_file_number: veteran.file_number,
        number_of_claimants: 1,
        request_issues: [
          FactoryBot.create(:request_issue, contested_issue_description: "Tinnitus", notes: "Tinnitus note"),
          FactoryBot.create(:request_issue, contested_issue_description: "Knee pain", notes: "Knee pain note")
        ]
      )
    end
    let!(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let!(:judge_task) do
      FactoryBot.create(:ama_judge_task, appeal: appeal, parent: root_task, assigned_to: judge_user, status: :assigned)
    end

    let(:document_id) { "5551212" }

    before do
      ["Elaine Abitong", "Byron Acero", "Jan Antonioni"].each do |attorney_name|
        another_attorney_on_the_team = FactoryBot.create(
          :user, station_id: User::BOARD_STATION_ID, full_name: attorney_name
        )
        FactoryBot.create(:staff, :attorney_role, user: another_attorney_on_the_team)
        OrganizationsUser.add_user_to_organization(another_attorney_on_the_team, judgeteam)
      end

      OrganizationsUser.add_user_to_organization(attorney_user, judgeteam)

      User.authenticate!(user: judge_user)
    end

    it "judge can return report to attorney for corrections" do
      step "judge reviews case and assigns a task to an attorney" do
        visit "/queue"

        click_on COPY::SWITCH_TO_ASSIGN_MODE_LINK_LABEL

        click_on veteran_full_name

        click_dropdown(prompt: "Select an action", text: "Assign to attorney")
        click_dropdown(prompt: "Select a user", text: attorney_user.full_name)

        click_on "Submit"

        expect(page).to have_content("Assigned 1 case")
      end

      step "attorney completes task and returns the case to the judge" do
        User.authenticate!(user: attorney_user)
        visit "/queue"

        click_on veteran_full_name

        click_dropdown(prompt: "Select an action", text: "Decision ready for review")

        expect(page).to have_content("Select special issues (optional)")
        click_label "riceCompliance"
        click_on "Continue"

        expect(page).to have_content("Select Dispositions")
        click_dropdown({ prompt: "Select disposition", text: "Allowed" }, find("#table-row-0"))
        click_dropdown({ prompt: "Select disposition", text: "Remanded" }, find("#table-row-1"))
        click_on "Continue"

        expect(page).to have_content("Select Remand Reasons")
        find_field("Legally inadequate notice", visible: false).sibling("label").click
        find_field("Post AOJ", visible: false).sibling("label").click
        click_on "Continue"

        expect(page).to have_content("Submit Draft Decision for Review")

        fill_in "Document ID:", with: "12345"
        click_on "Select a judge"
        click_dropdown(prompt: "Select a judge", text: judge_user.full_name)
        fill_in "notes", with: "all done"
        click_on "Continue"

        expect(page).to have_content(
          "Thank you for drafting #{veteran_full_name}'s decision. It's been "\
          "sent to #{judge_user.full_name} for review."
        )
      end

      step "judge returns case to attorney for corrections" do
        User.authenticate!(user: judge_user)
        visit "/queue"

        click_on veteran_full_name

        click_dropdown(prompt: "Select an action", text: "Return to attorney")
        expect(dropdown_selected_value(find(".cf-modal-body"))).to eq attorney_user.full_name
        fill_in "taskInstructions", with: "Please fix this"

        click_on "Submit"

        expect(page).to have_content("Task assigned to #{attorney_user.full_name}")
      end

      step "attorney corrects case and returns it to the judge" do
        User.authenticate!(user: attorney_user)
        visit "/queue"
        click_on veteran_full_name

        click_dropdown(prompt: "Select an action", text: "Decision ready for review")

        expect(page).to have_content("Select special issues (optional)")
        expect(page).to have_field("riceCompliance", checked: true, visible: false)
        click_on "Continue"

        expect(page).to have_content("Select Dispositions")
        expect(dropdown_selected_value(find("#table-row-0"))).to eq "Allowed"
        expect(dropdown_selected_value(find("#table-row-1"))).to eq "Remanded"
        click_on "Continue"

        expect(page).to have_content("Select Remand Reasons")
        expect(find_field("Legally inadequate notice", visible: false)).to be_checked
        expect(find_field("Post AOJ", visible: false)).to be_checked
        click_on "Continue"

        expect(page).to have_content("Submit Draft Decision for Review")

        fill_in "Document ID:", with: document_id
        click_on "Select a judge"
        click_dropdown(prompt: "Select a judge", text: judge_user.full_name)
        fill_in "notes", with: "corrections made"
        click_on "Continue"

        expect(page).to have_content(
          "Thank you for drafting #{veteran_full_name}'s decision. It's been "\
          "sent to #{judge_user.full_name} for review."
        )
      end

      step "judge sees the case in their queue" do
        User.authenticate!(user: judge_user)
        visit "/queue"

        expect(page).to have_content veteran_full_name
        expect(page).to have_content document_id
      end
    end
  end
end
