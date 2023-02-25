# frozen_string_literal: true

describe TaskActionRepository, :all_dbs do
  describe "#assign_to_user_data" do
    let(:organization) { create(:organization, name: "Organization") }
    let(:users) { create_list(:user, 3) + create_list(:user, 2, :inactive) }

    before do
      users.each { |user| organization.add_user(user) }
    end

    context "when assigned_to is an organization" do
      let(:task) { create(:ama_task, assigned_to: organization) }

      it "should return all active members" do
        match_users = users.reject(&:inactive?).map { |u| { label: u.full_name, value: u.id } }
        expect(TaskActionRepository.assign_to_user_data(task)[:options]).to match_array match_users
      end

      it "should return the task type of task" do
        expect(TaskActionRepository.assign_to_user_data(task)[:type]).to eq(task.type)
      end
    end

    context "when assigned_to's parent is an organization" do
      let(:parent) { create(:ama_task, assigned_to: organization) }
      let(:task) { create(:ama_task, assigned_to: users.first, parent: parent) }

      it "should return all members except user" do
        user_output = users[1..users.length - 1].reject(&:inactive?).map { |u| { label: u.full_name, value: u.id } }
        expect(TaskActionRepository.assign_to_user_data(task)[:options]).to match_array(user_output)
      end
    end

    context "when assigned_to is a user" do
      let(:task) { create(:ama_task, assigned_to: users.first) }

      it "should return all members except user" do
        expect(TaskActionRepository.assign_to_user_data(task)[:options]).to match_array([])
      end
    end
  end

  describe "#return_to_attorney_data" do
    let(:attorney) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Janet Avilez") }
    let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let(:judge) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let(:judge_task) { create(:ama_judge_decision_review_task, assigned_to: judge) }
    let!(:attorney_task) do
      create(:ama_attorney_task, assigned_to: attorney, parent: judge_task)
    end

    subject { TaskActionRepository.return_to_attorney_data(judge_task) }

    context "there aren't any attorneys on the JudgeTeam" do
      it "still shows the assigned attorney in selected and options" do
        expect(subject[:selected]).to eq attorney
        expect(subject[:options]).to eq [{ label: attorney.full_name, value: attorney.id }]
      end
    end

    context "there are attorneys on the JudgeTeam" do
      let(:attorney_names) { ["Jesse Abrecht", "Brenda Akery", "Crystal Andregg"] }

      before do
        judge_team.add_user(attorney)

        attorney_names.each do |attorney_name|
          another_attorney_on_the_team = create(
            :user, station_id: User::BOARD_STATION_ID, full_name: attorney_name
          )
          create(:staff, :attorney_role, user: another_attorney_on_the_team)
          judge_team.add_user(another_attorney_on_the_team)
        end
      end

      it "shows the assigned attorney in selected, and all attorneys in options" do
        expect(subject[:selected]).to eq attorney

        # + 1 because "attorney" is already in the judge team
        expect(judge_team.non_admins.count).to eq attorney_names.count + 1
        judge_team.non_admins.each do |team_attorney|
          expect(subject[:options]).to include(label: team_attorney.full_name, value: team_attorney.id)
        end
      end

      context "there are an attorneys on other judge teamd" do
        let(:other_teams_atty_names) { ["Wild E Beast", "Emory Millage", "Madalene Padavano", "Yvette Jessie Bailey"] }
        let(:other_teams_attorneys) { other_teams_atty_names.map { |atty_name| create(:user, full_name: atty_name) } }

        before do
          other_teams_attorneys.each do |atty_user|
            create(:staff, :attorney_role, user: atty_user)
            other_judge_team = JudgeTeam.create_for_judge(create(:user))
            other_judge_team.add_user(atty_user)
          end
        end

        it "includes attorneys on other judge teams in the list of options" do
          all_attorneys = judge_team.non_admins + other_teams_attorneys
          expected_options = all_attorneys.map { |atty| { label: atty.full_name, value: atty.id } }

          expect(subject[:options]).to match_array(expected_options)
        end
      end
    end
  end

  describe "#cancel_task_data" do
    let(:task) { create(:ama_task, assigned_by_id: assigner_id) }
    subject { TaskActionRepository.cancel_task_data(task) }

    context "when the task has no assigner" do
      let(:assigner_id) { nil }
      it "fills in the assigner name with placeholder text" do
        expect(subject[:message_detail]).to eq(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, "the assigner"))
      end
    end
  end

  describe "#vha caregiver support task actions" do
    describe "#vha_caregiver_support_return_to_board_intake" do
      let(:user) { create(:user) }
      let(:task) { create(:vha_document_search_task) }
      let(:completed_tab_name) { VhaCaregiverSupportCompletedTasksTab.tab_name }
      let(:redirect_url) { "/organizations/#{VhaCaregiverSupport.singleton.url}?tab=#{completed_tab_name}" }

      subject { TaskActionRepository.vha_caregiver_support_return_to_board_intake(task, user) }

      it "includes modal title, modal body text, and the redirect to the organization page" do
        expect(subject[:modal_title]).to eq(COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_TITLE)
        expect(subject[:modal_body]).to eq(COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_BODY)
        expect(subject[:redirect_after]).to eq(redirect_url)
      end
    end

    describe "#vha_caregiver_support_mark_task_in_progress" do
      let(:user) { create(:user) }
      let(:task) { create(:vha_document_search_task) }

      context "#vha_caregiver_support_mark_task_in_progress" do
        subject { TaskActionRepository.vha_caregiver_support_mark_task_in_progress(task, user) }

        it "the confirmation banner message title includes the veteran's name" do
          expect(COPY::VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS_CONFIRMATION_TITLE).to_not include(
            task.appeal.veteran_full_name
          )
          expect(subject[:message_title]).to include task.appeal.veteran_full_name
        end
      end
    end

    describe "#vha_caregiver_support_send_to_board_intake_for_review" do
      let(:user) { create(:user) }
      let(:task) { create(:vha_document_search_task) }

      context "#vha_caregiver_support_send_to_board_intake_for_review" do
        subject { TaskActionRepository.vha_caregiver_support_send_to_board_intake_for_review(task, user) }

        it "the confirmation banner message title includes the veteran's name" do
          expect(COPY::VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_CONFIRMATION_TITLE).to_not include(
            task.appeal.veteran_full_name
          )
          expect(subject[:message_title]).to include task.appeal.veteran_full_name
        end
      end
    end
  end
end
