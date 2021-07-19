# frozen_string_literal: true

feature "AmaQueue", :all_dbs do
  def valid_document_id
    "12345-12345678"
  end

  context "user with case details role " do
    let(:veteran_file_number) { 190_802_172 }
    let(:veteran) { create(:veteran, file_number: veteran_file_number, first_name: "Segan", last_name: "Vecellio") }
    let!(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
    let(:no_queue_user) { create(:user, roles: ["Case Details"]) }

    before do
      User.authenticate!(user: no_queue_user)
    end

    scenario "user visits queue" do
      step "is redirected to search" do
        visit "/queue"
        expect(page).to have_content("Search")
        expect(current_path).to eq "/search"
      end

      step "searches for a veteran and clicks the search result" do
        fill_in "searchBarEmptyList", with: appeal.veteran_file_number
        find("#submit-search-searchBarEmptyList").click
        click_on(appeal.docket_number)
      end

      step "views their case details which does not have the view docs link" do
        expect(page).to have_content("#{veteran.first_name} #{veteran.last_name}")
        expect(page).to_not have_content(COPY::TASK_SNAPSHOT_ABOUT_BOX_DOCUMENTS_LABEL)
      end
    end
  end

  context "loads appellant detail view" do
    let(:attorney_first_name) { "Robby" }
    let(:attorney_last_name) { "McDobby" }
    let!(:attorney_user) do
      create(:user, roles: ["Reader"], full_name: "#{attorney_first_name} #{attorney_last_name}")
    end

    let(:judge_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }

    let!(:vacols_atty) do
      create(
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
      Fakes::Initializer.load!

      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids).and_return(
        appeals.first.claimant.participant_id => {
          representative_name: poa_name,
          representative_type: "POA Attorney",
          participant_id: participant_id,
          file_number: appeals.first.veteran_file_number
        }
      )
    end

    let(:poa_address) { "123 Poplar St." }
    let(:participant_id) { "600153863" }
    let!(:root_task) { create(:root_task, appeal: appeals.first) }
    let!(:parent_task) do
      create(:ama_judge_assign_task, assigned_to: judge_user, parent: root_task)
    end

    let(:poa_name) { "Test POA" }
    let(:veteran_participant_id) { "600085544" }
    let(:file_numbers) { Array.new(3) { Random.rand(999_999_999).to_s } }
    let!(:appeals) do
      [
        create(
          :appeal,
          :advanced_on_docket_due_to_age,
          veteran: create(
            :veteran,
            participant_id: veteran_participant_id,
            first_name: "Pal",
            bgs_veteran_record: { first_name: "Pal" },
            file_number: file_numbers[0]
          ),
          documents: create_list(:document, 5, file_number: file_numbers[0], upload_date: 3.days.ago),
          request_issues: build_list(:request_issue, 3, contested_issue_description: "Knee pain")
        ),
        create(
          :appeal,
          veteran: create(:veteran, file_number: file_numbers[1]),
          documents: create_list(:document, 4, file_number: file_numbers[1]),
          request_issues: build_list(:request_issue, 2, contested_issue_description: "PTSD")
        ),
        create(
          :appeal,
          number_of_claimants: 1,
          veteran: create(:veteran, file_number: file_numbers[2]),
          documents: create_list(:document, 3, file_number: file_numbers[2]),
          request_issues: build_list(:request_issue, 1, contested_issue_description: "Tinnitus")
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
            parent: parent_task
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
        expect(page).to have_content("A. Judge", wait: 10)

        expect(page).to have_content("About the Veteran")

        expect(page).to have_content("AOD")
        expect(page).to have_content(appeals.first.request_issues.first.description)
        expect(page).to have_content(appeals.first.docket_number)
        expect(page).to have_content(poa_name)
        expect(page).to have_content(poa_address)

        expect(page.text).to match(/View (\d+) docs/)
        expect(page).not_to have_selector("text", id: "NEW")
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

        find(".cf-select__control", text: "Select grant or deny").click
        find("div", class: "cf-select__option", text: "Grant").click

        find(".cf-select__control", text: "Select a type").click
        find("div", class: "cf-select__option", text: "Serious illness").click

        click_on "Submit"

        expect(page).to have_content("AOD status has been granted due to Serious illness")
        expect(page).to have_content("AOD")
        motion = appeals.first.claimant.person.advance_on_docket_motions.first

        expect(motion.granted).to eq(true)
        expect(motion.reason).to eq(Constants.AOD_REASONS.serious_illness)
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
      let!(:translation_organization) { Translation.singleton }
      let!(:other_organization) { Organization.create!(name: "Other organization", url: "other") }

      let!(:translation_task) do
        create(
          :ama_task,
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
        translation_organization.add_user(user)
        translation_organization.add_user(other_user)
      end

      scenario "assign case to self" do
        visit translation_organization.path

        click_on "Pal Smith"

        find(".cf-select__control", text: "Select an action").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h[:label]).click

        find(".cf-select__control", text: user.full_name).click
        find("div", class: "cf-select__option", text: other_user.full_name).click

        expect(page).to have_content(existing_instruction)
        click_on "Submit"

        expect(page).to have_content("Task assigned to #{other_user_name}")
        expect(translation_task.reload.status).to eq("on_hold")

        visit "/organizations/#{translation_organization.url}"
        click_on "Assigned"
        click_on "Pal Smith"

        find(".cf-select__control", text: "Select an action").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h[:label]).click

        fill_in "taskInstructions", with: instructions
        click_on "Submit"

        expect(page).to have_content COPY::REASSIGN_TASK_SUCCESS_MESSAGE % user_name
        old_task = translation_task.reload.children.find { |task| task.assigned_to == other_user }
        expect(old_task.status).to eq(Constants.TASK_STATUSES.cancelled)

        # On hold tasks should not be visible on the case details screen
        # expect(page).to_not have_content("Actions")

        click_on "Caseflow"

        click_on "Pal Smith"

        within "#case-timeline-table" do
          click_button COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
          expect(page).to have_content(existing_instruction)
        end

        find(".cf-select__control", text: "Select an action").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h[:label]).click

        find(".cf-select__control", text: "Select a team").click
        find("div", class: "cf-select__option", text: other_organization.name).click
        fill_in "taskInstructions", with: instructions

        click_on "Submit"

        expect(page).to have_content("Task assigned to #{other_organization.name}")
        expect(Task.last.instructions.first).to eq(instructions)
      end

      context "A TranslationTask is assigned to the organization" do
        let(:veteran_first_name) { "Milivoj" }
        let(:veteran_last_name) { "Veilleux" }
        let(:veteran_full_name) { "#{veteran_first_name} #{veteran_last_name}" }
        let!(:veteran) { create(:veteran, first_name: veteran_first_name, last_name: veteran_last_name) }
        let!(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
        let!(:translation_task) do
          create(
            :translation_task,
            assigned_to: translation_organization,
            appeal: appeal,
            parent: appeal.root_task
          )
        end

        scenario "the task is in the organization queue" do
          visit translation_organization.path
          expect(page).to have_content(veteran_full_name)
        end
      end
    end

    context "when user is a vso" do
      let!(:user) do
        User.authenticate!(user: create(:user, roles: ["VSO"]))
      end

      let!(:appeals) do
        [
          create(
            :appeal,
            veteran: veteran,
            claimants: [build(:claimant, participant_id: participant_id)]
          ),
          create(
            :appeal,
            veteran: veteran,
            claimants: [build(:claimant, participant_id: participant_id_without_vso)]
          )
        ]
      end

      let(:veteran) { create(:veteran, file_number: "44556677") }

      let(:participant_id) { "1234" }
      let(:participant_id_without_vso) { "5678" }
      let(:vso_participant_id) { "2452383" }
      let(:participant_ids) { [participant_id, participant_id_without_vso] }
      let(:url) { "vietnam-veterans" }
      let(:name) { "Vietnam Veterans" }

      let!(:vso) do
        Vso.create(
          participant_id: vso_participant_id,
          url: url,
          name: name
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

  shared_examples "Judge has a case to assign to an attorney" do
    let(:veteran_first_name) { "Monica" }
    let(:veteran_last_name) { "Valencia" }
    let(:veteran_full_name) { "#{veteran_first_name} #{veteran_last_name}" }
    let!(:veteran) { create(:veteran, first_name: veteran_first_name, last_name: veteran_last_name) }

    let(:judge_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Anna Juarez") }
    let!(:judge_staff) { create(:staff, :judge_role, user: judge_user) }
    let!(:judgeteam) { JudgeTeam.create_for_judge(judge_user) }
    let(:overtime) { false }

    let(:attorney_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Steven Ahr") }
    let!(:attorney_staff) { create(:staff, :attorney_role, user: attorney_user) }

    let!(:appeal) do
      create(
        :appeal,
        veteran_file_number: veteran.file_number,
        number_of_claimants: 1,
        request_issues: [
          create(:request_issue, contested_issue_description: "Tinnitus", notes: "Tinnitus note"),
          create(
            :request_issue,
            contested_issue_description: "Knee pain",
            notes: "Knee pain note",
            contested_rating_issue_diagnostic_code: nil
          )
        ]
      )
    end
    let!(:root_task) { create(:root_task, appeal: appeal) }
    let!(:judge_task) do
      create(:ama_judge_assign_task, parent: root_task, assigned_to: judge_user, status: :assigned)
    end

    before do
      ["Elaine Abitong", "Byron Acero", "Jan Antonioni"].each do |attorney_name|
        another_attorney_on_the_team = create(
          :user, station_id: User::BOARD_STATION_ID, full_name: attorney_name
        )
        create(:staff, :attorney_role, user: another_attorney_on_the_team)
        judgeteam.add_user(another_attorney_on_the_team)
      end

      judgeteam.add_user(attorney_user)

      User.authenticate!(user: judge_user)
    end

    def judge_assign_to_attorney
      visit "/queue/#{judge_user.css_id}/assign"

      click_on veteran_full_name

      click_dropdown(prompt: "Select an action", text: "Assign to attorney")
      click_dropdown(prompt: "Select a user", text: attorney_user.full_name)
      fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "note")

      click_on "Submit"

      expect(page).to have_content("Assigned 1 task to #{attorney_user.full_name}")
    end

    it "judge can return report to attorney for corrections" do
      step "judge reviews case and assigns a task to an attorney" do
        judge_assign_to_attorney
      end

      step "attorney completes task and returns the case to the judge" do
        User.authenticate!(user: attorney_user)
        visit "/queue"

        click_on veteran_full_name

        click_dropdown(prompt: "Select an action", text: "Decision ready for review")

        expect(page.has_no_content?("Select special issues")).to eq(true)

        expect(page).to have_content("Add decisions")

        # Add a first decision issue
        all("button", text: "+ Add decision", count: 2)[0].click
        expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

        fill_in "Text Box", with: "test"

        find(".cf-select__control", text: "Select disposition").click
        find("div", class: "cf-select__option", text: "Allowed").click

        click_on "Save"

        # Add a second decision issue
        all("button", text: "+ Add decision", count: 2)[1].click
        expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE
        expect(page.find(".dropdown-Diagnostic.code")).to have_content("Diagnostic code")

        fill_in "Text Box", with: "test"

        find(".cf-select__control", text: "Select disposition").click
        find("div", class: "cf-select__option", text: "Remanded").click

        click_on "Save"
        expect(page.has_no_content?("This field is required")).to eq(true)
        click_on "Continue"

        expect(page).to have_content("Select Remand Reasons")
        find_field("Legally inadequate notice", visible: false).sibling("label").click
        find_field("Post AOJ", visible: false).sibling("label").click
        click_on "Continue"

        expect(page).to have_content("Submit Draft Decision for Review")
        # these now should be preserved the next time the attorney checks out
        fill_in "Document ID:", with: valid_document_id
        expect(page).to have_content(judge_user.full_name)
        fill_in "notes", with: "all done"
        click_on "Continue"

        expect(page).to have_content(
          "Thank you for drafting #{veteran_full_name}'s decision. It's been "\
          "sent to #{judge_user.full_name} for review."
        )

        expect(appeal.reload.latest_attorney_case_review.overtime).to be(overtime)
      end

      step "judge returns case to attorney for corrections" do
        User.authenticate!(user: judge_user)
        visit "/queue"

        click_on veteran_full_name

        click_dropdown(
          prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
          text: Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.label
        )
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

        expect(page.has_no_content?("Select special issues")).to eq(true)

        expect(page).to have_content("Add decisions")
        expect(page).to have_content("Allowed")
        expect(page).to have_content("Remanded")

        click_on "Continue"

        expect(page).to have_content("Select Remand Reasons")
        expect(find_field("Legally inadequate notice", visible: false)).to be_checked
        expect(find_field("Post AOJ", visible: false)).to be_checked
        click_on "Continue"

        expect(page).to have_content("Submit Draft Decision for Review")

        fill_in "Document ID:", with: valid_document_id
        expect(page).to have_content(judge_user.full_name)
        fill_in "notes", with: "corrections made"
        click_on "Continue"
        expect(page).to have_content(
          "Thank you for drafting #{veteran_full_name}'s decision. It's been "\
          "sent to #{judge_user.full_name} for review."
        )
      end

      step "judge sees the case in their review queue" do
        User.authenticate!(user: judge_user)
        visit "/queue"

        expect(page).to have_content veteran_full_name
        expect(page).to have_content valid_document_id
      end
    end

    it "checkout details (documentID, judge, attorney notes) are preserved in attorney checkout" do
      step "judge reviews case and assigns a task to an attorney" do
        judge_assign_to_attorney
      end

      step "attorney completes task and returns the case to the judge" do
        User.authenticate!(user: attorney_user)
        visit "/queue"

        click_on veteran_full_name

        click_dropdown(prompt: "Select an action", text: "Decision ready for review")

        expect(page.has_no_content?("Select special issues")).to eq(true)

        expect(page).to have_content("Add decisions")

        # Add a first decision issue
        all("button", text: "+ Add decision", count: 2)[0].click
        expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

        fill_in "Text Box", with: "test"

        find(".cf-select__control", text: "Select disposition").click
        find("div", class: "cf-select__option", text: "Allowed").click

        click_on "Save"

        # Add a second decision issue
        all("button", text: "+ Add decision", count: 2)[1].click
        expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

        fill_in "Text Box", with: "test"

        find(".cf-select__control", text: "Select disposition").click
        find("div", class: "cf-select__option", text: "Remanded").click

        click_on "Save"
        click_on "Continue"

        expect(page).to have_content("Select Remand Reasons")
        find_field("Legally inadequate notice", visible: false).sibling("label").click
        find_field("Post AOJ", visible: false).sibling("label").click
        click_on "Continue"

        expect(page).to have_content("Submit Draft Decision for Review")

        fill_in "Document ID:", with: valid_document_id
        expect(page).to have_content(judge_user.full_name)
        fill_in "notes", with: "all done"
        click_label("untimely_evidence")
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

        click_dropdown(
          prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
          text: Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.label
        )
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

        expect(page.has_no_content?("Select special issues")).to eq(true)

        expect(page).to have_content("Add decisions")
        click_on "Continue"

        expect(page).to have_content("Select Remand Reasons")
        expect(find_field("Legally inadequate notice", visible: false)).to be_checked
        expect(find_field("Post AOJ", visible: false)).to be_checked
        click_on "Continue"

        expect(page).to have_content("Submit Draft Decision for Review")
        # info below should be preserved from attorney completing the task
        document_id_node = find("#document_id")
        notes_node = find("#notes")
        expect(page).to have_field("untimely_evidence", type: "checkbox", visible: false) do |node|
          node.value == "on"
        end
        expect(document_id_node.value).to eq valid_document_id
        expect(page).to have_content(judge_user.full_name)
        expect(notes_node.value).to eq "all done"
        click_on "Continue"
        expect(page).to have_content(
          "Thank you for drafting #{veteran_full_name}'s decision. It's been "\
          "sent to #{judge_user.full_name} for review."
        )
      end

      step "judge sees the case in their review queue" do
        User.authenticate!(user: judge_user)
        visit "/queue"

        expect(page).to have_content veteran_full_name
        expect(page).to have_content valid_document_id
      end
    end

    context "multiple judges" do
      let(:judge_user2) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Andrea R. Harless") }
      let!(:judge_staff2) { create(:staff, :judge_role, user: judge_user2) }
      let!(:judgeteam2) { JudgeTeam.create_for_judge(judge_user2) }

      it "judge can reassign the assign task to another judge" do
        step "judge reviews case and reassigns to another judge" do
          visit "/queue"
          expect(page).to have_content(COPY::USER_QUEUE_PAGE_TABLE_TITLE)

          find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
          expect(page).to have_content(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user.css_id))
          click_on format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user.css_id)

          click_on veteran_full_name

          click_dropdown(prompt: "Select an action", text: "Re-assign to a judge")
          click_dropdown(prompt: "Select a user", text: judge_user2.full_name)

          fill_in "taskInstructions", with: "Going on leave, please manage this case"
          click_on "Submit"

          expect(page).to have_content("Task reassigned to #{judge_user2.full_name}")
        end
        step "judge2 has the case in their queue" do
          User.authenticate!(user: judge_user2)
          visit "/queue"
          expect(page).to have_content(COPY::USER_QUEUE_PAGE_TABLE_TITLE)

          find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
          expect(page).to have_content(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user2.css_id))
          click_on format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user2.css_id)

          click_on veteran_full_name
        end
      end

      it "judge can reassign the review judge tasks to another judge" do
        step "judge reviews case and assigns a task to an attorney" do
          visit "/queue"
          expect(page).to have_content(COPY::USER_QUEUE_PAGE_TABLE_TITLE)

          find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
          expect(page).to have_content(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user.css_id))
          click_on format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user.css_id)

          click_on veteran_full_name

          # wait for page to load with veteran name
          expect(page).to have_content(veteran_full_name)

          click_dropdown(prompt: "Select an action", text: "Assign to attorney")
          click_dropdown(prompt: "Select a user", text: attorney_user.full_name)
          fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "note")

          click_on "Submit"

          expect(page).to have_content("Assigned 1 task to #{attorney_user.full_name}")
        end

        step "attorney completes task and returns the case to the judge" do
          User.authenticate!(user: attorney_user)
          visit "/queue"

          click_on veteran_full_name

          click_dropdown(prompt: "Select an action", text: "Decision ready for review")

          expect(page.has_no_content?("Select special issues")).to eq(true)

          expect(page).to have_content("Add decisions")

          # Add a first decision issue
          all("button", text: "+ Add decision", count: 2)[0].click
          expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

          fill_in "Text Box", with: "test"

          find(".cf-select__control", text: "Select disposition").click
          find("div", class: "cf-select__option", text: "Allowed").click

          click_on "Save"

          # Add a second decision issue
          all("button", text: "+ Add decision", count: 2)[1].click
          expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE
          expect(page.find(".dropdown-Diagnostic.code")).to have_content("Diagnostic code")

          fill_in "Text Box", with: "test"

          find(".cf-select__control", text: "Select disposition").click
          find("div", class: "cf-select__option", text: "Remanded").click

          click_on "Save"
          expect(page.has_no_content?("This field is required")).to eq(true)
          click_on "Continue"

          expect(page).to have_content("Select Remand Reasons")
          find_field("Legally inadequate notice", visible: false).sibling("label").click
          find_field("Post AOJ", visible: false).sibling("label").click
          click_on "Continue"

          expect(page).to have_content("Submit Draft Decision for Review")
          # these now should be preserved the next time the attorney checks out
          fill_in "Document ID:", with: valid_document_id
          expect(page).to have_content(judge_user.full_name, wait: 10)
          fill_in "notes", with: "all done"
          click_on "Continue"

          expect(page).to have_content(
            "Thank you for drafting #{veteran_full_name}'s decision. It's been "\
            "sent to #{judge_user.full_name} for review."
          )
        end

        step "judge reviews case and reassigns to another judge" do
          User.authenticate!(user: judge_user)
          visit "/queue"
          expect(page).to have_content(COPY::USER_QUEUE_PAGE_TABLE_TITLE)

          click_on veteran_full_name

          click_dropdown(prompt: "Select an action", text: "Re-assign to a judge")
          click_dropdown(prompt: "Select a user", text: judge_user2.full_name)

          fill_in "taskInstructions", with: "Going on leave, please manage this case"
          click_on "Submit"

          expect(page).to have_content("Task reassigned to #{judge_user2.full_name}")
        end

        step "judge2 has the case in their queue" do
          User.authenticate!(user: judge_user2)
          visit "/queue"
          expect(page).to have_content(COPY::USER_QUEUE_PAGE_TABLE_TITLE)

          click_on veteran_full_name
        end
      end
    end
  end

  it_behaves_like "Judge has a case to assign to an attorney"

  context "overtime_revamp feature enabled with different overtime values" do
    before { FeatureToggle.enable!(:overtime_revamp) }
    after { FeatureToggle.disable!(:overtime_revamp) }
    it_behaves_like "Judge has a case to assign to an attorney" do
      let(:overtime) { true }
      before { appeal.overtime = overtime }
    end
    it_behaves_like "Judge has a case to assign to an attorney" do
      let(:overtime) { false }
    end
  end

  describe "Navigating between team and individual queues" do
    let(:user) { create(:user) }
    let(:org) { create(:organization) }

    let(:task_count) { 2 }
    let!(:tasks) do
      Array.new(task_count) do
        root_task = create(:root_task)
        create(:ama_task, parent: root_task, assigned_to: org)
      end
    end

    before do
      org.add_user(user)
      User.authenticate!(user: user)
    end

    it "successfully loads the individual queue " do
      step "Assign the first organization task to a member of the team" do
        visit("#{org.path}?tab=unassigned&page=1")
        click_on(tasks.first.appeal.veteran.file_number)
        click_dropdown(
          prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
          text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label
        )
        fill_in("taskInstructions", with: "instructions here")
        click_on(COPY::MODAL_SUBMIT_BUTTON)
        expect(page).to have_content(COPY::USER_QUEUE_PAGE_TABLE_TITLE)
      end

      step "Use the back button to return to the team queue to retain data stored in front-end state" do
        page.go_back # Case details page
        page.go_back # Team queue
        expect(page).to have_content(format(COPY::ORGANIZATION_QUEUE_TABLE_TITLE, org.name))
      end

      step "Assign the second organization task to a member of the team" do
        visit(org.path)
        click_on(tasks.second.appeal.veteran.file_number)
        click_dropdown(
          prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
          text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label
        )
        fill_in("taskInstructions", with: "instructions here")
        click_on(COPY::MODAL_SUBMIT_BUTTON)
        expect(page).to have_content(COPY::USER_QUEUE_PAGE_TABLE_TITLE)
      end
    end
  end
end
