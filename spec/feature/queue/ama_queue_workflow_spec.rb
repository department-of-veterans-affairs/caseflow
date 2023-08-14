feature "Attorney checkout flow", :all_dbs do
  include IntakeHelpers

  let!(:bva_intake_admin_user) { create(:user, roles: ["Mail Intake"]) }
  let!(:bva_intake) { BvaIntake.singleton }

  let!(:vanilla_vet) do
    Generators::Veteran.build(file_number: "67845673", first_name: "Bryan", last_name: "Libby", participant_id: "23434565")
  end
  let!(:veteran) do
    create(
      :veteran,
      first_name: "Vick",
      bgs_veteran_record: {
        first_name: "Vick",
        address_line1: "1234 Main Street",
        country: "USA",
        zip_code: "12345",
        state: "FL",
        city: "Orlando",
        file_number: file_numbers[0],
      },
      file_number: file_numbers[0]
    )
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
    veteran: veteran,
    documents: create_list(:document, 5, file_number: file_numbers[0], upload_date: 4.days.ago),
    request_issues: build_list(:request_issue, 3, contested_issue_description: "Knee pain",
       decision_date: 2.days.ago, veteran_participant_id: veteran.participant_id),
  )
  end
  # Creation of vanilla vet. This is a vet without a contention.
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

  let!(:root_task2) { create(:root_task, appeal: appeal_vanilla_vet) }
  let!(:parent_task2) do
    create(:ama_judge_assign_task, appeal: appeal_vanilla_vet, assigned_to: judge_user, parent: root_task2)
  end

  let(:poa_name2) { "Test POA" }
  let(:veteran_participant_id2) { "600085544" }

  let(:judge_task2) do
    create(
      :ama_judge_decision_review_task,
      appeal: appeal_vanilla_vet,
      assigned_to: judge_user,
      parent: root_task2
    )
  end

  let!(:attorney_tasks2) do
    create(
        :ama_attorney_task,
        assigned_to: attorney_user,
        assigned_by: judge_user,
        appeal: appeal_vanilla_vet,
        parent: judge_task2
      )
  end

  let!(:colocated_team) do
    Colocated.singleton.tap { |org| org.add_user(create(:user)) }
  end

  before do
    User.authenticate!(user: bva_intake_admin_user)
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
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
      add_intake_nonrating_issue(date: "01/01/2023")
      click_on "Save"
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
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      check("PACT Act", allow_label_click: true, visible: false)
      add_intake_nonrating_issue(date: "01/01/2023")
      click_on "Save"
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
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
      click_on "+ Add issue"
      check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
      check("PACT Act", allow_label_click: true, visible: false)
      add_intake_nonrating_issue(date: "01/01/2023")
      click_on "Save"
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
      generate_rating_with_mst_pact(veteran)
      visit "/appeals/#{appeal.uuid}/edit"
      visit "/appeals/#{appeal.uuid}/edit"
      click_on "+ Add issue"
      choose('rating-radio_3', allow_label_click:true)
      check("Issue is related to Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
      click_on "Next"
      click_on "Save"
      click_on "Yes, save"
      visit "/queue/appeals/#{appeal.uuid}"
      refresh
      click_on "View task instructions"
      expect(page).to have_content("Special Issues: MST")
    end
  end


  context " AC 1.5 It passes the feature tests for adding a new issue appeal PACT" do
    before do
      # creates admin user
      # joins the user with the organization to grant access to role and org permissions
      OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
      FeatureToggle.enable!(:mst_identification)
      FeatureToggle.enable!(:pact_identification)
      FeatureToggle.enable!(:acd_distribute_by_docket_date)
    end
    scenario "Adding a new issue with PACT" do
      generate_rating_with_mst_pact(veteran)
      visit "/appeals/#{appeal.uuid}/edit"
      visit "/appeals/#{appeal.uuid}/edit"
      click_on "+ Add issue"
      choose('rating-radio_3', allow_label_click:true)
      check("Issue is related to PACT Act", allow_label_click: true, visible: false)
      click_on "Next"
      click_on "Save"
      click_on "Yes, save"
      visit "/queue/appeals/#{appeal.uuid}"
      refresh
      click_on "View task instructions"
      expect(page).to have_content("Special Issues: PACT")
    end
  end

  context " AC 1.6 It passes the feature tests for adding a new issue appeal MST & PACT" do
    before do
      # creates admin user
      # joins the user with the organization to grant access to role and org permissions
      OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
      FeatureToggle.enable!(:mst_identification)
      FeatureToggle.enable!(:pact_identification)
      FeatureToggle.enable!(:acd_distribute_by_docket_date)
    end
    scenario "Adding a new issue with MST & PACT" do
      generate_rating_with_mst_pact(veteran)
      visit "/appeals/#{appeal.uuid}/edit"
      visit "/appeals/#{appeal.uuid}/edit"
      click_on "+ Add issue"
      choose('rating-radio_3', allow_label_click:true)
      check("Issue is related to Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
      check("Issue is related to PACT Act", allow_label_click: true, visible: false)
      click_on "Next"
      click_on "Save"
      click_on "Yes, save"
      visit "/queue/appeals/#{appeal.uuid}"
      refresh
      click_on "View task instructions"
      expect(page).to have_content("Special Issues: MST and PACT")
    end
  end

  context " AC 2.5 It passes the feature tests for adding a new issue appeal MST & PACT coming from a contention, then removing the MST/PACT designation" do
    before do
      # creates admin user
      # joins the user with the organization to grant access to role and org permissions
      OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
      FeatureToggle.enable!(:mst_identification)
      FeatureToggle.enable!(:pact_identification)
      FeatureToggle.enable!(:acd_distribute_by_docket_date)
    end
    scenario "Adding a new issue with MST & PACT" do
      generate_rating_with_mst_pact(veteran)
      visit "/appeals/#{appeal.uuid}/edit"
      visit "/appeals/#{appeal.uuid}/edit"
      click_on "+ Add issue"
      choose('rating-radio_2', allow_label_click:true)
      click_on "Next"
      find('#issue-action-3').find(:xpath, 'option[3]').select_option
      find("label[for='Military Sexual Trauma (MST)']").click
      find("label[for='PACT Act']").click
      find("#Edit-issue-button-id-1").click
      click_on "Save"
      click_on "Yes, save"
      visit "/queue/appeals/#{appeal.uuid}"
      refresh
      expect(page).to have_content("Special Issues: None")
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
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    check("PACT Act", allow_label_click: true, visible: false)
    add_intake_nonrating_issue(date: "01/01/2023")
    find('#issue-action-3').find(:xpath, 'option[3]').select_option
    check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
    find("#Edit-issue-button-id-1").click
    click_on "Save"
    click_on "Yes, save"
    visit "/queue/appeals/#{appeal_vanilla_vet.uuid}"
    refresh
    click_on "View task instructions"
    expect(page).to have_content("Special Issues: MST and PACT")
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
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
    add_intake_nonrating_issue(date: "01/01/2023")
    find('#issue-action-3').find(:xpath, 'option[3]').select_option
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
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    add_intake_nonrating_issue(date: "01/01/2023")
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
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    click_on "+ Add issue"
    add_intake_nonrating_issue(date: "01/01/2023")
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

#Removing an issue on an appeal
context "AC 3.1 ,3.2 ,3.3 It passes the feature tests for removing an issue on an appeal with MST + PACT" do
  before do
    # creates admin user
    # joins the user with the organization to grant access to role and org permissions
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
    FeatureToggle.enable!(:mst_identification)
    FeatureToggle.enable!(:pact_identification)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
  end
  scenario "Removing an issue on an appeal with MST + PACT" do
    appeal_vanilla_vet.request_issues[0].update(mst_status: true)
    appeal_vanilla_vet.request_issues[1].update(pact_status: true)
    appeal_vanilla_vet.request_issues[2].update(mst_status: true, pact_status: true)
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    visit "/appeals/#{appeal_vanilla_vet.uuid}/edit"
    # Adding issue so entire appeal is deleted
    click_on "+ Add issue"
    add_intake_nonrating_issue(date: "01/01/2023")
    3.times do
      find('#issue-action-0').find(:xpath, 'option[2]').select_option
      click_on "Yes, remove issue"
    end
    click_on "Save"
    click_on "Yes, save"
    sleep(3)
    expect(page).to have_content("You have successfully added 1 issue and removed 3 issues.")
  end
end


end
