# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module CorrespondenceHelpers
  def current_user
    User.find_or_create_by(
      css_id: "TEST_USER",
      full_name: "Test User",
      email: "testuser@example.com",
      station_id: 101,
      roles: ["Mail Team"]
    )
  end

  def seed_database
    require Rails.root.join("db/seeds/base.rb").to_s
    Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }
    Seeds::Correspondence.new.create_auto_text_data
  end

  def setup_access
    FeatureToggle.enable!(:correspondence_queue)
    InboundOpsTeam.singleton.add_user(current_user)
    MailTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)

    mock_doc_uploader = instance_double(CorrespondenceDocumentsEfolderUploader)

    allow(CorrespondenceDocumentsEfolderUploader).to receive(:new).and_return(mock_doc_uploader)
    allow(mock_doc_uploader).to receive(:upload_documents_to_claim_evidence).and_return(true)
  end

  def visit_intake_form_with_correspondence_load(return_veteran: false)
    setup_access
    veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
    create(
      :correspondence,
      :with_correspondence_intake_task,
      assigned_to: current_user,
      veteran_id: veteran.id,
      uuid: SecureRandom.uuid,
      va_date_of_receipt: Time.zone.local(2023, 1, 1)
    )
    53.times do
      cor = create(
        :correspondence,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
      cor.review_package_task.update!(status: Constants.TASK_STATUSES.completed)
    end
    find_and_route_to_intake
    return_veteran ? veteran : nil
  end

  def visit_intake_form_step_2_with_appeals
    setup_access
    veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
    appeals = (1..20).map { create(:appeal, veteran_file_number: veteran.file_number, docket_type: "direct_review") }
    appeals.each do |appeal|
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
    end
    3.times do
      create(
        :correspondence,
        :with_correspondence_intake_task,
        assigned_to: current_user,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
    end
    find_and_route_to_intake
    click_button("Continue")
  end

  def visit_intake_form_step_2_with_inactive_appeals
    setup_access
    veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
    appeals = (1..10).map { create(:appeal, veteran_file_number: veteran.file_number, docket_type: "direct_review") }
    appeals.each do |appeal|
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
    end
    appeals.each do |appeal|
      appeal.root_task.update!(status: Constants.TASK_STATUSES.completed)
    end
    3.times do
      create(
        :correspondence,
        :with_correspondence_intake_task,
        assigned_to: current_user,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
    end
    find_and_route_to_intake
    click_button("Continue")
  end

  def visit_intake_form_step_2_with_appeals_without_initial_tasks
    setup_access
    veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
    13.times { create(:appeal, veteran_file_number: veteran.file_number, docket_type: "direct_review") }
    3.times do
      create(
        :correspondence,
        :with_correspondence_intake_task,
        assigned_to: current_user,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
    end
    find_and_route_to_intake
    click_button("Continue")
  end

  def visit_intake_form_step_3_with_tasks_unrelated
    setup_access
    create(
      :correspondence,
      :with_correspondence_intake_task,
      assigned_to: current_user,
      uuid: SecureRandom.uuid,
      va_date_of_receipt: Time.zone.local(2023, 1, 1)
    )
    find_and_route_to_intake
    click_button("Continue")
    click_button("+ Add tasks")
    all("#reactSelectContainer")[0].click
    find_by_id("react-select-2-option-0").click
    find_by_id("content", visible: :all).fill_in with: "Correspondence test text"
    click_button("Continue")
  end

  def associate_with_prior_mail_radio_options
    radio_options = page.all(".cf-form-radio-option")
    { yes: radio_options[0], no: radio_options[1] }
  end

  def existing_appeal_radio_options
    radio_options = page.all(".cf-form-radio-option")
    { yes: radio_options[0], no: radio_options[1] }
  end

  def active_evidence_submissions_tasks
    setup_access
    veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
    create(
      :correspondence,
      :with_correspondence_intake_task,
      assigned_to: current_user,
      veteran_id: veteran.id,
      uuid: SecureRandom.uuid,
      va_date_of_receipt: Time.zone.local(2023, 1, 1)
    )
    2.times do
      appeal = create(:appeal, veteran_file_number: veteran.file_number)
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
    end
    find_and_route_to_intake
    click_button("Continue")
  end

  def setup_and_visit_intake
    FeatureToggle.enable!(:correspondence_queue)
    create(
      :correspondence,
      :with_correspondence_intake_task,
      uuid: SecureRandom.uuid,
      va_date_of_receipt: Time.zone.local(2023, 1, 1)
    )
    @correspondence_uuid = Correspondence.first.uuid
    correspondence.tasks.find_by(type: CorrespondenceIntakeTask.name).reload
    visit "/queue/correspondence/#{@correspondence_uuid}/intake"
  end

  def seed_autotext_table
    require Rails.root.join("db/seeds/base.rb").to_s
    Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }
    Seeds::Correspondence.new.create_auto_text_data
  end

  def find_and_route_to_intake
    correspondence = Correspondence.first
    correspondence.tasks.find_by(type: CorrespondenceIntakeTask.name).reload
    visit "/queue/correspondence/#{correspondence.uuid}/intake"
  end

  def inbound_ops_team_admin_setup
    InboundOpsTeam.singleton.add_user(current_user)
    MailTeam.singleton.add_user(current_user)
    OrganizationsUser.find_or_create_by!(
      organization: InboundOpsTeam.singleton,
      user: current_user
    ).update!(admin: true)
    User.authenticate!(user: current_user)
  end

  def click_page_body
    find("body").click
  end

  # rubocop:enable Metrics/ModuleLength
end
