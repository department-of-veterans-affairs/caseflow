feature "Attorney checkout flow", :all_dbs do

  let!(:vanilla_vet){build(:veteran)}

  let(:attorney_first_name) { "Robby" }
  let(:attorney_last_name) { "McDobby" }
  let!(:attorney_user) do
    create(:user, full_name: "#{attorney_first_name} #{attorney_last_name}")
  end

  let!(:vacols_attorney) { create(:staff, :attorney_role, user: attorney_user) }

  let(:judge_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }
  let!(:vacols_judge) { create(:staff, :judge_role, user: judge_user) }

  let!(:judge_team) do
    JudgeTeam.create_for_judge(judge_user).tap { |jt| jt.add_user(attorney_user) }
  end
  let!(:vacols_atty) do
    create(
      :staff,
      :attorney_role,
      sdomainid: attorney_user.css_id,
      snamef: attorney_first_name,
      snamel: attorney_last_name
    )
  end
 # creation of vet with contention
  let(:file_numbers) { Array.new(3) { Random.rand(999_999_999).to_s } }
  let! (:appeal) do
  create(
    :appeal,
    :advanced_on_docket_due_to_age,
    created_at: 3.months.ago,
    veteran: create(
      :veteran,
      participant_id: veteran_participant_id,
      first_name: "Pal",
      bgs_veteran_record: { first_name: "Pal" },
      file_number: file_numbers[0]
    ),
    documents: create_list(:document, 5, file_number: file_numbers[0], upload_date: 3.days.ago),
    request_issues: build_list(:request_issue, 3, contested_issue_description: "Knee pain",
       decision_date: 3.months.ago, veteran_participant_id: veteran_participant_id),
  )
  end
  # creation of vanilla vet
  let! (:appeal_vanilla_vet) do
  create(
    :appeal,
    :advanced_on_docket_due_to_age,
    created_at: 3.months.ago,
    veteran:
      vanilla_vet,
    documents: create_list(:document, 5, file_number: file_numbers[0], upload_date: 3.days.ago),
    request_issues: build_list(:request_issue, 3, contested_issue_description: "Knee pain",
       decision_date: 3.months.ago, veteran_participant_id: veteran_participant_id),
  )
  end


  let!(:poa_address) { "123 Poplar St." }
  let!(:participant_id) { "600153863" }

  #This task is for holding legacy appeals. The factory will create an attached legacy appeal. Attach an attorney task
  # from :attorney task
  # let!(:legacy_appeal_task) do
  #   build(:task, id:"1010", assigned_to: attorney_user, assigned_by_id: "3",
  #     assigned_to_id:"2", assigned_to_type: "User" , type: "AttorneyTask", created_at: 5.days.ago)
  # end

  let!(:root_task) { create(:root_task, appeal: appeal) }
  let!(:parent_task) do
    create(:ama_judge_assign_task, appeal: appeal, assigned_to: judge_user, parent: root_task)
  end

  let(:poa_name) { "Test POA" }
  let(:veteran_participant_id) { "600085544" }

  let(:judge_task) do
    create(
      :ama_judge_decision_review_task,
      appeal: appeal,
      assigned_to: judge_user,
      parent: root_task
    )
  end

  let!(:attorney_tasks) do
    create(
        :ama_attorney_task,
        assigned_to: attorney_user,
        assigned_by: judge_user,
        appeal: appeal,
        parent: judge_task
      )
  end

  let!(:colocated_team) do
    Colocated.singleton.tap { |org| org.add_user(create(:user)) }
  end

  # let!(:colocated_task) do
  #   create(
  #     :colocated_task,
  #     appeal: legacy_appeal_task.appeal,
  #     assigned_by: attorney_user,
  #     parent: attorney_tasks
  #   )
  # end


  before do
    User.authenticate!(user: attorney_user, roles: ["System Admin"])
   ## appeal.decision_date = 5.days.ago
  end
#Adding a new issue to appeal
  context "AC 1.1 It passes the feature tests for adding a new issue appeal MST" do
    before { FeatureToggle.enable!(:mst_identification)}
    before { FeatureToggle.enable!(:pact_identification)}
    before { FeatureToggle.enable!(:justification_reason)}
    scenario "Adding a new issue with MST" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      # add the benefit type
      dropdown_select_string = "Select or enter..."
      dropdown_select_string = "Select or enter..."
      benefit_text = "Compensation"
      sleep(30000000000000)
      # add the issue category
      dropdown_select_string = "Select or enter..."
      benefit_text = "Active Duty Adjustments"
      # fill in date and issue description
      fill_in "Decision date", with: 1.day.ago.to_date.mdY.to_s
      fill_in "Issue description", with: "Test MST"
      click_on "Military Sexual Trauma (MST)"
      click_on "Add this issue"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      sleep(30000)
      #Remove issue
    end
    end
  context "AC 1.2 It passes the feature tests for adding a new issue appeal PACT" do
    scenario "Adding a new issue with PACT" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      # add the benefit type
      dropdown_select_string = "Select or enter..."
      benefit_text = "Compensation"
      # add the issue category
      dropdown_select_string = "Select or enter..."
      benefit_text = "Active Duty Adjustments"
      # fill in date and issue description
      fill_in "Decision date", with: 1.day.ago.to_date.mdY.to_s
      fill_in "Issue description", with: "Test PACT"
      click_on "PACT Act"
      click_on "Add this issue"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      sleep(30000)
      #Remove issue
    end
    end
  context "AC 1.3 It passes the feature tests for adding a new issue appeal MST + PACT" do
    scenario "Adding a new issue with MST" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      # add the benefit type
      dropdown_select_string = "Select or enter..."
      benefit_text = "Compensation"
      # add the issue category
      dropdown_select_string = "Select or enter..."
      benefit_text = "Active Duty Adjustments"
      # fill in date and issue description
      fill_in "Decision date", with: 1.day.ago.to_date.mdY.to_s
      fill_in "Issue description", with: "Test MST + PACT"
      click_on "Military Sexual Trauma (MST)"
      click_on "PACT Act"
      click_on "Add this issue"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      sleep(30000)
      #Remove issue
    end
    end
#Adding a new issue to appeal coming from a contention
  context " AC 1.4 It passes the feature tests for adding a new issue appeal MST" do
    scenario "Adding a new issue with MST" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal.uuid}/edit"
      #visit "/queue/appeals/#{appeals[0].uuid}"
      click_on "+ Add issue"
      choose('rating-radio_0', allow_label_click:true)
      click_on "Issue is related to Military Sexual Trauma (MST)"
      click_on "Next"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      sleep(30000)
      #Remove issue
    end
    end
  context "AC 1.5 It passes the feature tests for adding a new issue appeal PACT" do
    scenario "Adding a new issue with PACT" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal.uuid}/edit"
      #visit "/queue/appeals/#{appeals[0].uuid}"
      click_on "+ Add issue"
      choose('rating-radio_0', allow_label_click:true)
      click_on "Issue is related to PACT Act"
      click_on "Next"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      sleep(30000)
      #Remove issue
    end
    end
  context "AC 1.6 It passes the feature tests for adding a new issue appeal MST & PACT" do
    scenario "Adding a new issue with MST & PACT" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal.uuid}/edit"
      #visit "/queue/appeals/#{appeals[0].uuid}"
      click_on "+ Add issue"
      choose('rating-radio_0', allow_label_click:true)
      click_on "Issue is related to Military Sexual Trauma (MST)"
      click_on "Issue is related to PACT Act"
      click_on "Next"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      sleep(30000)
      #Remove issue
    end
    end

  context "AC 2.5 It passes the feature tests for adding a new issue appeal MST & PACT and removing it" do
    scenario "Adding a new issue with MST & PACT and removing it" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal.uuid}/edit"
      #visit "/queue/appeals/#{appeals[0].uuid}"
      click_on "+ Add issue"
      choose('rating-radio_0', allow_label_click:true)
      click_on "Issue is related to Military Sexual Trauma (MST)"
      click_on "Issue is related to PACT Act"
      click_on "Next"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      sleep(30000)
      #Remove issue
    end
    end

#Editing an issue on an appeal
  context " AC 2.1 It passes the feature tests for editing an issue on an appeal by adding MST" do
    scenario "Editing issue with MST existing issue" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      sleep(30000)
      choose('rating-radio_0', allow_label_click:true)
      click_on "Issue is related to PACT Act"
      click_on "Next"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Edit issue"
      click_on "Military Sexual Trauma (MST)"
      click_on "Save"
      sleep(30000)
      #Edited appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      #Remove issue
      sleep(30000)
    end
    end
  context "AC 2.2 It passes the feature tests for editing an issue on an appeal by adding PACT" do
    scenario "Editing issue with PACT existing issue" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      sleep(30000)
      choose('rating-radio_0', allow_label_click:true)
      click_on "Issue is related to MST Act"
      click_on "Next"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Edit issue"
      click_on "PACT Act"
      click_on "Save"
      sleep(30000)
      #Edited appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      #Remove issue
      sleep(30000)
    end
    end
  context "AC 2.3/2.4 It passes the feature tests for editing an issue on an appeal by adding MST + PACT" do
    scenario "Editing issue with MST + PACT on existing issue" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      sleep(30000)
      choose('rating-radio_0', allow_label_click:true)
      click_on "Next"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Edit issue"
      click_on "Military Sexual Trauma (MST)"
      click_on "PACT Act"
      click_on "Save"
      sleep(30000)
      #Edited appeal MST + Pact
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      sleep(30000)
      #Remove issue
    end
    end
# Adding a new issue with MST/PACT coming from a contention
    context "AC 2.5 It passes the feature tests for adding a new issue appeal MST & PACT from a contention" do
      scenario "Adding a new issue with MST & PACT from a contention then removing it" do
        #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
        visit "/appeals/#{appeal.uuid}/edit"
        #visit "/queue/appeals/#{appeals[0].uuid}"
        click_on "+ Add issue"
        choose('rating-radio_0', allow_label_click:true)
        click_on "Issue is related to Military Sexual Trauma (MST)"
        click_on "Issue is related to PACT Act"
        click_on "Next"
        sleep(30000)
        #Added appeal
        click_on "Select action"
        click_on "Remove issue"
        click_on "Yes, remove issue"
        sleep(30000)
        #Remove issue
      end
      end

#Removing an issue on an appeal
  context "AC 3.1 It passes the feature tests for removing an issue on an appeal with MST" do
    scenario "Removing existing issue with MST" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      sleep(30000)
      choose('rating-radio_0', allow_label_click:true)
      click_on "Edit issue"
      click_on "Issue is related to MST Act"
      click_on "Next"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      #Remove issue
      sleep(30000)
    end
    end
  context " AC 3.2 It passes the feature tests for removing an issue on an appeal with PACT" do
    scenario "Removing existing issue with PACT" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      sleep(30000)
      choose('rating-radio_0', allow_label_click:true)
      click_on "Edit issue"
      click_on "Issue is related to PACT Act"
      click_on "Next"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      sleep(30000)
      #Remove issue
    end
    end
  context "AC 3.3 It passes the feature tests for removing an issue on an appeal with MST + PACT" do
    scenario "Removing existing issue with MST + PACT" do
      #allow_any_instance_of(AppealsController).to receive(receipt_date).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      sleep(30000)
      choose('rating-radio_0', allow_label_click:true)
      click_on "Edit issue"
      click_on "Issue is related to MST Act"
      click_on "Issue is related to PACT Act"
      click_on "Next"
      sleep(30000)
      #Added appeal
      click_on "Select action"
      click_on "Remove issue"
      click_on "Yes, remove issue"
      sleep(30000)
      #Remove issue
    end
    end

end
