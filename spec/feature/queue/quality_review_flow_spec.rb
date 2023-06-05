# frozen_string_literal: true

RSpec.feature "Quality Review workflow", :all_dbs do
  let(:judge_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Javitz") }
  let!(:judge_staff) { create(:staff, :judge_role, user: judge_user) }

  context "return case to judge" do
    let(:valid_document_id) { "12345-12345678" }

    let(:veteran_first_name) { "Marissa" }
    let(:veteran_last_name) { "Vasquez" }
    let(:veteran_full_name) { "#{veteran_first_name} #{veteran_last_name}" }
    let!(:veteran) { create(:veteran, first_name: veteran_first_name, last_name: veteran_last_name) }

    let(:qr_user_name) { "QR User" }
    let(:qr_user_name_short) { "Q. User" }
    let!(:qr_user) { create(:user, roles: ["Reader"], full_name: qr_user_name) }

    let(:attorney_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Nicole Apple") }
    let!(:attorney_staff) { create(:staff, :attorney_role, user: attorney_user) }

    let!(:quality_review_organization) { QualityReview.singleton }
    let!(:other_organization) { Organization.create!(name: "Other organization", url: "other") }
    let!(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
    let!(:request_issue) { create(:request_issue, decision_review: appeal) }

    let!(:root_task) { create(:root_task, appeal: appeal) }
    let!(:judge_task) do
      create(
        :ama_judge_decision_review_task,
        :completed,
        appeal: appeal,
        parent: root_task,
        assigned_to: judge_user
      )
    end
    let!(:attorney_task) do
      create(
        :ama_attorney_task,
        :completed,
        appeal: appeal,
        parent: judge_task,
        assigned_to: attorney_user
      )
    end
    let!(:qr_task) do
      create(
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
        create(
          :staff,
          :judge_role,
          user: create(:user, station_id: User::BOARD_STATION_ID, full_name: judge_name)
        )
      end

      BvaDispatch.singleton.add_user(create(:user))

      create(:staff, user: qr_user, sattyid: nil)
      quality_review_organization.add_user(qr_user)
      User.authenticate!(user: qr_user)
    end

    it "completes end to end test with accurate data" do
      expect(QualityReviewTask.count).to eq 1

      step "QR user visits the quality review organization page and assigns the task to themself" do
        visit quality_review_organization.path
        click_on "#{veteran_full_name} (#{veteran.file_number})"

        find(".cf-select__control", text: "Select an action").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h[:label]).click

        fill_in "taskInstructions", with: "Review the quality"
        click_on "Submit"

        expect(page).to have_content("Task assigned to #{qr_user_name}")

        expect(QualityReviewTask.count).to eq 2
      end

      step "QR user returns the case to a judge" do
        click_on "Caseflow"

        click_on "#{veteran_full_name} (#{veteran.file_number})"

        find(".cf-select__control", text: "Select an action").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.QR_RETURN_TO_JUDGE.to_h[:label]).click

        expect(dropdown_selected_value(find(".cf-modal-body"))).to eq judge_user.full_name
        fill_in "taskInstructions", with: qr_instructions

        click_on "Submit"

        expect(page).to have_content("On hold (1)")
      end

      step "judge reviews case and assigns a task to an attorney" do
        User.authenticate!(user: judge_user)

        visit "/queue"

        judge_qa_review_task = JudgeQualityReviewTask.first
        find("#veteran-name-for-task-#{judge_qa_review_task.id}").click

        find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL, match: :first).click

        expect(page).to have_content(qr_instructions)

        find(".cf-select__control", text: "Select an action", match: :first).click
        find(
          "div",
          class: "cf-select__option",
          text: Constants.TASK_ACTIONS.JUDGE_QR_RETURN_TO_ATTORNEY.to_h[:label]
        ).click

        expect(dropdown_selected_value(find(".cf-modal-body"))).to eq attorney_user.full_name
        click_on "Submit"

        expect(page).to have_content("Task assigned to #{attorney_user.full_name}")
      end

      step "attorney completes task and returns the case to the judge" do
        User.authenticate!(user: attorney_user)

        visit "/queue"

        click_on "#{veteran_full_name} (#{veteran.file_number})"

        find(".cf-select__control", text: "Select an action").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.REVIEW_AMA_DECISION.to_h[:label]).click

        find("label", text: "No Special Issues").click
        click_on "Continue"

        expect(page).to have_content("Add decisions")
        all("button", text: "+ Add decision", count: 1)[0].click
        expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

        fill_in "Text Box", with: "test"
        find(".cf-select__control", text: "Select disposition").click
        find("div", class: "cf-select__option", text: "Allowed").click

        click_on "Save"

        click_on "Continue"

        expect(page).to have_content("Submit Draft Decision for Review")

        fill_in "Document ID:", with: valid_document_id
        # the judge should be pre selected
        expect(page).to have_content(judge_user.full_name)
        fill_in "notes", with: "all done"

        click_on "Continue"

        expect(page).to have_content(
          "Thank you for drafting #{veteran_full_name}'s decision. " \
          "It's been sent to #{judge_user.full_name} for review."
        )
      end

      step "judge completes task" do
        User.authenticate!(user: judge_user)

        visit "/queue"

        judge_qa_review_task = JudgeQualityReviewTask.first
        find("#veteran-name-for-task-#{judge_qa_review_task.id}").click

        find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL, match: :first).click
        expect(page).to have_content(qr_instructions)

        find(".cf-select__control", text: "Select an action", match: :first).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.to_h[:label]).click

        expect(page).to have_content("Mark as complete")

        click_on "Mark complete"

        expect(page).to have_content("#{veteran_full_name}'s case has been marked complete")
      end

      step "QR reviews case" do
        User.authenticate!(user: qr_user)

        visit "/queue"

        click_on "#{veteran_full_name} (#{veteran.file_number})"

        expect(page).to have_content(COPY::CASE_TIMELINE_ATTORNEY_TASK)
        find(".cf-select__control", text: "Select an action").click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.to_h[:label]).click

        expect(page).to have_content("Mark as complete")

        click_on "Mark complete"

        expect(page).to have_content("#{veteran_full_name}'s case has been marked complete")
        # ensure no duplicate org tasks
        page.go_back

        page.find("table#case-timeline-table").assert_text("QualityReviewTask", count: 1)
      end
    end
  end

  describe "creating a child task for a task on a timed hold" do
    let(:root_task) { create(:root_task) }

    let(:appeal) { root_task.appeal }
    let(:veteran_name) { appeal.veteran.name.formatted(:readable_full) }
    let(:hold_length) { 30 }

    let!(:judge_task) do
      create(:ama_judge_assign_task, :completed, parent: root_task, assigned_to: judge_user)
    end
    let!(:qr_org_task) { QualityReviewTask.create_from_root_task(root_task) }

    let(:user) do
      create(:user).tap do |user|
        QualityReview.singleton.add_user(user)
      end
    end

    it "cancels the existing timed hold" do
      User.authenticate!(user: user)

      step "assign task to current user" do
        visit("/queue/appeals/#{appeal.uuid}")
        click_dropdown(text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label)
        click_dropdown({ text: user.full_name }, find(".cf-modal-body"))
        fill_in("instructions", with: "assigning to QR team member")
        click_on(COPY::MODAL_SUBMIT_BUTTON)
        expect(page).to have_content(format(COPY::ASSIGN_TASK_SUCCESS_MESSAGE, user.full_name))
      end

      step "place the task on hold" do
        visit("/queue/appeals/#{appeal.uuid}")
        click_dropdown(text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)
        click_dropdown(prompt: COPY::COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL, text: hold_length)
        fill_in("instructions", with: "placing task on hold")
        click_on(COPY::MODAL_SUBMIT_BUTTON)
        expect(page).to have_content(format(COPY::COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, veteran_name, hold_length))
      end

      step "confim task has been placed on hold" do
        qr_person_task = qr_org_task.children.first
        expect(qr_person_task.assigned_to).to eq(user)
        expect(qr_person_task.on_timed_hold?).to eq(true)
      end

      step "return the case to the judge" do
        visit("/queue/appeals/#{appeal.uuid}")
        click_dropdown(text: Constants.TASK_ACTIONS.QR_RETURN_TO_JUDGE.label)
        fill_in("taskInstructions", with: "returning to judge")
        click_on(COPY::MODAL_SUBMIT_BUTTON)
      end

      step "confirm that the task is on hold but timed hold is cancelled" do
        qr_person_task = qr_org_task.children.first
        expect(page).to have_content(format(COPY::ASSIGN_TASK_SUCCESS_MESSAGE, judge_user.full_name))
        expect(qr_person_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(qr_person_task.on_timed_hold?).to eq(false)
      end
    end
  end
end
