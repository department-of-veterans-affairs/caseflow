feature "Attorney checkout flow", :all_dbs do
  include IntakeHelpers

  let!(:bva_intake_admin_user) { create(:user, roles: ["Mail Intake"]) }
  let!(:bva_intake) { BvaIntake.singleton }

  let!(:vanilla_vet) do
    Generators::Veteran.build(file_number: "67845673", first_name: "Bryan", last_name: "Libby", participant_id: "23434565")
  end

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
    created_at: 1.day.ago,
    veteran: create(
      :veteran,
      participant_id: veteran_participant_id,
      first_name: "Pal",
      bgs_veteran_record: { first_name: "Pal" },
      file_number: file_numbers[0]
    ),
    documents: create_list(:document, 5, file_number: file_numbers[0], upload_date: 4.days.ago),
    request_issues: build_list(:request_issue, 3, contested_issue_description: "Knee pain",
       decision_date: 2.days.ago, veteran_participant_id: veteran_participant_id),
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
    documents: create_list(:document, 5, file_number: file_numbers[0], upload_date: 4.days.ago),
    request_issues: build_list(:request_issue, 3, contested_issue_description: "Knee pain",
       decision_date: 2.days.ago, veteran_participant_id: veteran_participant_id),
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
    User.authenticate!(user: bva_intake_admin_user)
  #  appeal_vanilla_vet.update(decision_date: 5.days.ago)
  end
#Adding a new issue to appeal
  context "AC 1.1 It passes the feature tests for adding a new issue appeal MST" do
    before do
      # creates admin user
      # joins the user with the organization to grant access to role and org permissions
      OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
      FeatureToggle.enable!(:mst_identification)
      FeatureToggle.enable!(:pact_identification)
      FeatureToggle.enable!(:acd_distribute_by_docket_date)
    end
    scenario "Adding a new issue with MST" do
      # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      # add the benefit type
      check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
      add_intake_nonrating_issue(date: "01/01/2023")
      click_on "Save"
      # binding.pry
      click_on "Yes, save"
      visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
      refresh
      click_on "View task instructions"
      expect(page).to have_content("Special Issues: MST")
    end
  end
  context "AC 1.2 It passes the feature tests for adding a new issue appeal PACT" do
    before do
      # creates admin user
      # joins the user with the organization to grant access to role and org permissions
      OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
      FeatureToggle.enable!(:mst_identification)
      FeatureToggle.enable!(:pact_identification)
      FeatureToggle.enable!(:acd_distribute_by_docket_date)
    end
    scenario "Adding a new issue with PACT" do
      # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      # add the benefit type
      check("PACT Act", allow_label_click: true, visible: false)
      add_intake_nonrating_issue(date: "01/01/2023")
      click_on "Save"
      # binding.pry
      click_on "Yes, save"
      visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
      refresh
      click_on "View task instructions"
      expect(page).to have_content("Special Issues: PACT")
    end
  end
  context "AC 1.3 It passes the feature tests for adding a new issue appeal MST + PACT" do
    before do
      # creates admin user
      # joins the user with the organization to grant access to role and org permissions
      OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
      FeatureToggle.enable!(:mst_identification)
      FeatureToggle.enable!(:pact_identification)
      FeatureToggle.enable!(:acd_distribute_by_docket_date)
    end
    scenario "Adding a new issue with PACT" do
      # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      # add the benefit type
      check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
      check("PACT Act", allow_label_click: true, visible: false)
      add_intake_nonrating_issue(date: "01/01/2023")
      click_on "Save"
      # binding.pry
      click_on "Yes, save"
      visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
      refresh
      click_on "View task instructions"
      expect(page).to have_content("Special Issues: MST and PACT")
    end
  end

#Adding a new issue to appeal coming from a contention
  context " AC 1.4 It passes the feature tests for adding a new issue appeal MST" do
    before do
      # creates admin user
      # joins the user with the organization to grant access to role and org permissions
      OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
      FeatureToggle.enable!(:mst_identification)
      FeatureToggle.enable!(:pact_identification)
      FeatureToggle.enable!(:acd_distribute_by_docket_date)
    end
    scenario "Adding a new issue with MST" do
      # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
      visit "/appeals/#{appeal.uuid}/edit"
      visit "/appeals/#{appeal.uuid}/edit"
      click_on "+ Add issue"
      # add the benefit type
      check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
      add_intake_nonrating_issue(date: "01/01/2023")
      click_on "Save"
      click_on "Yes, save"
      find('#issue-action-3').find(:xpath, 'option[3]').select_option
      visit "/queue/appeals/#{appeal.uuid}"
      refresh
      click_on "View task instructions"
      expect(page).to have_content("Special Issues: MST")
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
  before do
    # creates admin user
    # joins the user with the organization to grant access to role and org permissions
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
    FeatureToggle.enable!(:mst_identification)
    FeatureToggle.enable!(:pact_identification)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
  end
  scenario "Editing an issue with MST" do
    # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    # add the benefit type
    check("PACT Act", allow_label_click: true, visible: false)
    add_intake_nonrating_issue(date: "01/01/2023")
    click_on "Save"
    click_on "Yes, save"
    # binding.pry
    find('#issue-action-3').find(:xpath, 'option[3]').select_option
    # binding.pry
    check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
    find("#Edit-issue-button-id-1").click
    visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
    refresh
    click_on "View task instructions"
    expect(page).to have_content("Special Issues: MST + PACT")
  end
end

context "AC 2.2 It passes the feature tests for editing an issue on an appeal by adding PACT" do
  before do
    # creates admin user
    # joins the user with the organization to grant access to role and org permissions
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
    FeatureToggle.enable!(:mst_identification)
    FeatureToggle.enable!(:pact_identification)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
  end
  scenario "Editing an issue with MST" do
    # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    # add the benefit type
    check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
    add_intake_nonrating_issue(date: "01/01/2023")
    click_on "Save"
    click_on "Yes, save"
    # binding.pry
    find('#issue-action-3').find(:xpath, 'option[3]').select_option
    find("label[for='PACT Act']").click
    find("#Edit-issue-button-id-1").click
    visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
    refresh
    click_on "View task instructions"
    expect(page).to have_content("Special Issues: MST and PACT")
  end
end

context "AC 2.3 It passes the feature tests for editing an issue on an appeal by adding MST + PACT" do
  before do
    # creates admin user
    # joins the user with the organization to grant access to role and org permissions
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
    FeatureToggle.enable!(:mst_identification)
    FeatureToggle.enable!(:pact_identification)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
  end
  scenario "Editing an issue with MST + PACT" do
    # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    # add the benefit type
    add_intake_nonrating_issue(date: "01/01/2023")
    # binding.pry
    find('#issue-action-3').find(:xpath, 'option[3]').select_option
    check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
    find("label[for='PACT Act']").click
    find("#Edit-issue-button-id-1").click
    click_on "Save"
    click_on "Yes, save"
    visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
    refresh
    click_on "View task instructions"
    expect(page).to have_content("Special Issues: MST and PACT")
  end
end
context "AC 2.4 It passes the feature tests for editing an issue on an appeal by removing PACT" do
  before do
    # creates admin user
    # joins the user with the organization to grant access to role and org permissions
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
    FeatureToggle.enable!(:mst_identification)
    FeatureToggle.enable!(:pact_identification)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
  end
  scenario "Editing an issue with MST" do
    # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    # add the benefit type
    add_intake_nonrating_issue(date: "01/01/2023")
    # binding.pry
    find('#issue-action-3').find(:xpath, 'option[3]').select_option
    check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
    find("label[for='PACT Act']").click
    find("#Edit-issue-button-id-1").click
    find('#issue-action-3').find(:xpath, 'option[3]').select_option
    find("label[for='PACT Act']").click
    find("#Edit-issue-button-id-1").click
    click_on "Save"
    click_on "Yes, save"
    visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
    refresh
    click_on "View task instructions"
    expect(page).to have_content("Special Issues: MST")
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
  before do
    # creates admin user
    # joins the user with the organization to grant access to role and org permissions
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
    FeatureToggle.enable!(:mst_identification)
    FeatureToggle.enable!(:pact_identification)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
  end
  scenario "Removing an issue on an appeal with MST" do
    # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    # add the benefit type
    check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
    add_intake_nonrating_issue(date: "01/01/2023")
    click_on "Save"
    click_on "Yes, save"
    find('#issue-action-3').find(:xpath, 'option[2]').select_option
    click_on "Yes, remove issue"
    # binding.pry
    click_on "Save"
    click_on "Yes, save"
    visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
    refresh
    click_on "View task instructions"
    expect(page).to have_content("Special Issues: None")
  end
end

context "AC 3.2 It passes the feature tests for removing an issue on an appeal with PACT" do
  before do
    # creates admin user
    # joins the user with the organization to grant access to role and org permissions
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
    FeatureToggle.enable!(:mst_identification)
    FeatureToggle.enable!(:pact_identification)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
  end
  scenario "Removing an issue on an appeal with PACT" do
    # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    # add the benefit type
    check("PACT Act", allow_label_click: true, visible: false)
    add_intake_nonrating_issue(date: "01/01/2023")
    click_on "Save"
    click_on "Yes, save"
    find('#issue-action-3').find(:xpath, 'option[2]').select_option
    click_on "Yes, remove issue"
    # binding.pry
    click_on "Save"
    click_on "Yes, save"
    visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
    refresh
    click_on "View task instructions"
    expect(page).to have_content("Special Issues: None")
  end
end

context "AC 3.3 It passes the feature tests for removing an issue on an appeal with MST + PACT" do
  before do
    # creates admin user
    # joins the user with the organization to grant access to role and org permissions
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
    FeatureToggle.enable!(:mst_identification)
    FeatureToggle.enable!(:pact_identification)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
  end
  scenario "Removing an issue on an appeal with MST + PACT" do
    # allow_any_instance_of(AppealsController).to receive(appeal_vanilla_vet.receipt_date.to_s).and_return(5.days.ago)
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    # add the benefit type
    check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
    check("PACT Act", allow_label_click: true, visible: false)
    add_intake_nonrating_issue(date: "01/01/2023")
    click_on "Save"
    click_on "Yes, save"
    find('#issue-action-3').find(:xpath, 'option[2]').select_option
    click_on "Yes, remove issue"
    # binding.pry
    click_on "Save"
    click_on "Yes, save"
    visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
    refresh
    click_on "View task instructions"
    expect(page).to have_content("Special Issues: None")
  end
end


end
