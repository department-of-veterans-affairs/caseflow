# frozen_string_literal: true

RSpec.feature "SpecialCaseMovementTask", :all_dbs do
  let(:scm_user) { create(:user) }

  let(:judge_user) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
  let!(:judgeteam) { JudgeTeam.create_for_judge(judge_user) }
  let(:veteran) { create(:veteran, first_name: "Samuel", last_name: "Purcell") }
  let(:appeal) do
    create(:appeal,
           :with_post_intake_tasks,
           veteran: veteran,
           docket_type: Constants.AMA_DOCKETS.direct_review)
  end

  before do
    SpecialCaseMovementTeam.singleton.add_user(scm_user)
    User.authenticate!(user: scm_user)
  end
  describe "Case Movement Team Member" do
    context "With the Appeal in the right state" do
      it "successfully assigns the task to judge" do
        visit("queue/appeals/#{appeal.external_id}")

        prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
        text = Constants.TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.label
        click_dropdown(prompt: prompt, text: text)

        # Select a judge, fill in instructions, submit
        click_dropdown(prompt: COPY::SPECIAL_CASE_MOVEMENT_MODAL_SELECTOR_PLACEHOLDER,
                       text: judge_user.full_name)
        fill_in("taskInstructions", with: "instructions")
        click_button("Submit")

        expect(page).to have_content(COPY::ASSIGN_TASK_SUCCESS_MESSAGE % judge_user.full_name)
        # Auth as judge user
        User.authenticate!(user: judge_user)
        visit "/queue"
        find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
        expect(page).to have_content(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user.css_id))
        click_on format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user.css_id)
        expect(page).to have_content("Cases to Assign")
        # Expect to find case in Assign Queue
        expect(page).to have_content("#{veteran.first_name} #{veteran.last_name}")
        # Expect to see the SCM in the timeline
        click_on "#{veteran.first_name} #{veteran.last_name}"
        expect(page).to have_content(SpecialCaseMovementTask.name)
      end
    end

    context "With the blocking tasks on the appeal" do
      before do
        OrganizationsUser.make_user_admin(bva_admin, Bva.singleton)
        Colocated.singleton.add_user(colocated_user)
        FeatureToggle.enable!(:scm_move_with_blocking_tasks, users: [scm_user.css_id])
      end
      after { FeatureToggle.disable!(:scm_move_with_blocking_tasks) }

      let(:appeal) { create(:appeal, :with_post_intake_tasks, :hearing_docket, veteran: veteran) }
      let(:dist_task) { appeal.tasks.find_by(type: DistributionTask.name) }
      let!(:blocking_mail_task) do
        DeathCertificateMailTask.create!(appeal: appeal, parent: dist_task, assigned_to: MailTeam.singleton)
      end
      let!(:blocking_mail_child_task) do
        DeathCertificateMailTask.create!(appeal: appeal, parent: blocking_mail_task, assigned_to: Colocated.singleton)
      end
      let!(:blocking_mail_user_task) do
        DeathCertificateMailTask.create!(appeal: appeal, parent: blocking_mail_child_task, assigned_to: colocated_user)
      end
      let!(:non_blocking_mail_task) do
        AodMotionMailTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: MailTeam.singleton)
      end

      let(:bva_admin) { create(:user, email: "admin@va.gov") }
      let(:colocated_user) { create(:user, email: "colocated@va.gov") }

      it "successfully assigns the task to judge and cancels blocking tasks" do
        visit("queue/appeals/#{appeal.external_id}")

        prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
        text = Constants.TASK_ACTIONS.BLOCKED_SPECIAL_CASE_MOVEMENT.label
        click_dropdown(prompt: prompt, text: text)
        expect(page).to have_content(COPY::BLOCKED_SPECIAL_CASE_MOVEMENT_PAGE_SUBTITLE)

        # Ensure we have a list of blocking tasks only
        expect(page).to have_content(DeathCertificateMailTask.name)
        expect(page).to have_content(colocated_user.css_id)
        expect(page).to have_content(HearingTask.name)
        expect(page).to have_content(Bva.singleton.name)
        expect(page).to have_content(ScheduleHearingTask.name)
        expect(page).to have_no_content(AodMotionMailTask.name)

        # Validate before moving on
        click_on "Continue"
        expect(page).to have_content(COPY::FORM_ERROR_FIELD_REQUIRED)
        find("label", text: "Death dismissal").click
        fill_in("cancellationInstructions", with: "Instructions for cancellation")
        click_on "Continue"

        # Validate before moving on
        click_on "Cancel Task and Reassign"
        expect(page).to have_content(COPY::FORM_ERROR_FIELD_REQUIRED)
        click_dropdown(prompt: "Select...", text: judge_user.full_name)
        fill_in("judgeInstructions", with: "Instructions for the judge")
        click_on "Cancel Task and Reassign"

        # Check case timeline
        expect(page).to have_content(COPY::ASSIGN_TASK_SUCCESS_MESSAGE % judge_user.full_name)
        expect(page).to have_content("#{DeathCertificateMailTask.name} cancelled")
        expect(page).to have_content("#{HearingTask.name} cancelled")
        expect(page).to have_content("#{ScheduleHearingTask.name} cancelled")
        expect(page).to have_content("CANCELLED BY\n#{scm_user.css_id}")
        page.find_all(".taskInformationTimelineContainerStyling button", text: "View task instructions").first.click
        expect(page).to have_content("TASK INSTRUCTIONS\nDeath dismissal: Instructions for cancellation")

        expect(page).to have_content("#{BlockedSpecialCaseMovementTask.name} completed")
        expect(page).to have_content("#{DistributionTask.name} completed")
        expect(page).to have_no_content("#{AodMotionMailTask.name} cancelled")

        # Auth as judge user
        User.authenticate!(user: judge_user)
        visit "/queue"
        find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
        expect(page).to have_content(format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user.css_id))
        click_on format(COPY::JUDGE_ASSIGN_DROPDOWN_LINK_LABEL, judge_user.css_id)
        expect(page).to have_content("Cases to Assign")
        # Expect to find case in Assign Queue
        expect(page).to have_content("#{veteran.first_name} #{veteran.last_name}")
        # Expect to see the SCM in the timeline
        click_on "#{veteran.first_name} #{veteran.last_name}"
        page.find_all("#currently-active-tasks button", text: "View task instructions").first.click
        expect(page).to have_content("Instructions for the judge")
      end
    end
  end
end
