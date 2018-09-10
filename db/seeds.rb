# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require "database_cleaner"
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
class SeedDB
  def initialize
    @legacy_appeals = []
    @tasks = []
    @users = []
    @ama_appeals = []
  end

  def create_legacy_appeals(number)
    legacy_appeals = Array.new(number) do |i|
      Generators::LegacyAppeal.create(
        vacols_id: "vacols_id#{i}",
        vbms_id: "vbms_id#{i}",
        vacols_record: {
          status: "Remand"
        }
      )
    end

    @legacy_appeals.push(*legacy_appeals)
    @legacy_appeals.push(LegacyAppeal.create(vacols_id: "reader_id1", vbms_id: "reader_id1"))
  end

  def create_users
    User.create(css_id: "BVASCASPER1", station_id: 101, full_name: "Attorney with cases")
    User.create(css_id: "BVASRITCHIE", station_id: 101, full_name: "Attorney no cases")
    User.create(css_id: "BVAAABSHIRE", station_id: 101, full_name: "Judge with hearings and cases")
    User.create(css_id: "BVARERDMAN", station_id: 101, full_name: "Judge has attorneys with cases")
    User.create(css_id: "BVAOFRANECKI", station_id: 101, full_name: "Judge has case to sign")
    User.create(css_id: "BVAJWEHNER", station_id: 101, full_name: "Judge has case to assign no team")
    User.create(css_id: "BVALSPORER", station_id: 101, full_name: "Co-located no cases")
    User.create(css_id: "BVATWARNER", station_id: 101, full_name: "Build Hearing Schedule")

    Functions.grant!("System Admin", users: User.all.pluck(:css_id))

    u = User.create(
      css_id: "VSO",
      station_id: 101,
      full_name: "VSO user associated with american-legion",
      roles: ["VSO"]
    )
    FeatureToggle.enable!(:vso_queue_aml, users: [u.css_id])

    q = User.create!(station_id: 101, css_id: "ORG_QUEUE_USER", full_name: "Org Q User")
    FeatureToggle.enable!(:org_queue_translation, users: [q.css_id])
    FeatureToggle.enable!(:organization_queue, users: [q.css_id])
  end

  def create_dispatch_tasks(number)
    num_appeals = @legacy_appeals.length
    tasks = Array.new(number) do |i|
      establish_claim = EstablishClaim.create(
        appeal: @legacy_appeals[i % num_appeals],
        aasm_state: :unassigned,
        prepared_at: rand(3).days.ago
      )
      establish_claim
    end

    # creating user quotas for the existing team quotas
    team_quota = EstablishClaim.todays_quota
    UserQuota.create(team_quota: team_quota, user: @users[3])
    UserQuota.create(team_quota: team_quota, user: @users[4])
    UserQuota.create(team_quota: team_quota, user: @users[5])

    # Give each user a task in a different state
    tasks[0].assign!(@users[0])

    tasks[1].assign!(@users[1])
    tasks[1].start!

    tasks[2].assign!(@users[2])
    tasks[2].start!
    tasks[2].review!
    tasks[2].complete!(status: :routed_to_arc)

    # assigning and moving the task to complete for
    # user at index 3
    5.times do |_index|
      task = EstablishClaim.assign_next_to!(@users[3])
      task.start!
      task.review!
      task.complete!(status: :routed_to_arc)
    end

    task = EstablishClaim.assign_next_to!(@users[4])

    # assigning and moving the task to complete for
    # user at index 5
    3.times do |_index|
      task = EstablishClaim.assign_next_to!(@users[5])
      task.start!
      task.review!
      task.complete!(status: :routed_to_arc)
    end

    task = EstablishClaim.assign_next_to!(@users[6])

    # Create one task with no decision documents
    EstablishClaim.create(
      appeal: tasks[2].appeal,
      created_at: 5.days.ago
    )

    @tasks.push(*tasks)
  end

  def create_default_users
    @users.push(
      User.create(
        css_id: "Reader",
        station_id: "405",
        full_name: "VBMS Station ID maps to multiple VACOLS IDs"
      )
    )
    @users.push(User.create(css_id: "Invalid Role", station_id: "283", full_name: "Cave Johnson"))
    @users.push(User.create(css_id: "Establish Claim", station_id: "283", full_name: "Jane Smith"))
    @users.push(User.create(css_id: "Establish Claim", station_id: "405", full_name: "Carole Johnson"))
    @users.push(User.create(css_id: "Manage Claim Establishment", station_id: "283", full_name: "John Doe"))
    @users.push(User.create(css_id: "Certify Appeal", station_id: "283", full_name: "John Smith"))
    @users.push(User.create(css_id: "System Admin", station_id: "283", full_name: "Angelina Smith"))
    @users.push(User.create(css_id: "Reader", station_id: "283", full_name: "Angelina Smith"))
    @users.push(User.create(css_id: "Hearing Prep", station_id: "283", full_name: "Lauren Roth"))
    @users.push(User.create(css_id: "Mail Intake", station_id: "283", full_name: "Kwame Nkrumah"))
    @users.push(User.create(css_id: "Admin Intake", station_id: "283", full_name: "Ash Ketchum"))
  end

  def create_annotations
    Generators::Annotation.create(comment: "Hello World!", document_id: 1, x: 300, y: 400)
    Generators::Annotation.create(comment: "This is an example comment", document_id: 2)
  end

  def create_ramp_elections(number)
    number.times do |i|
      RampElection.create!(
        veteran_file_number: "#{i + 1}5555555",
        notice_date: 1.week.ago
      )
    end

    %w[11555555 12555555].each do |i|
      RampElection.create!(
        veteran_file_number: i,
        notice_date: 3.weeks.ago
      )
    end
  end

  def create_tags
    DocumentsTag.create(
      tag_id: Generators::Tag.create(text: "Service Connected").id,
      document_id: 1
    )
    DocumentsTag.create(
      tag_id: Generators::Tag.create(text: "Right Knee").id,
      document_id: 2
    )
  end

  def create_hearings
    Generators::Hearing.create
  end

  def create_api_key
    ApiKey.new(consumer_name: "PUBLIC", key_string: "PUBLICDEMO123").save!
  end

  def create_ama_appeals
    @ama_appeals << FactoryBot.create(
      :appeal,
      veteran_file_number: "701305078",
      request_issues: FactoryBot.build_list(:request_issue, 3, description: "Knee pain")
    )
    @appeal_with_vso = FactoryBot.create(
      :appeal,
      claimants: [
        FactoryBot.build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO"),
        FactoryBot.build(:claimant, participant_id: "OTHER_CLAIMANT")
      ],
      veteran_file_number: "701305078",
      request_issues: FactoryBot.build_list(:request_issue, 3, description: "Head trauma")
    )
    @ama_appeals << @appeal_with_vso
    @ama_appeals << FactoryBot.create(
      :appeal,
      veteran_file_number: "963360019",
      request_issues: FactoryBot.build_list(:request_issue, 2, description: "PTSD")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "604969679",
      request_issues: FactoryBot.build_list(:request_issue, 1, description: "Tinnitus")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "228081153",
      request_issues: FactoryBot.build_list(:request_issue, 1, description: "Tinnitus")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "152003980",
      request_issues: FactoryBot.build_list(:request_issue, 3, description: "PTSD")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "375273128",
      request_issues: FactoryBot.build_list(:request_issue, 1, description: "Knee pain")
    )

    LegacyAppeal.create(vacols_id: "2096907", vbms_id: "228081153S")
    LegacyAppeal.create(vacols_id: "2226048", vbms_id: "213912991S")
    LegacyAppeal.create(vacols_id: "2249056", vbms_id: "608428712S")
    LegacyAppeal.create(vacols_id: "2306397", vbms_id: "779309925S")
  end

  def create_tasks
    attorney = User.find_by(css_id: "BVASCASPER1")
    judge = User.find_by(css_id: "BVAAABSHIRE")
    colocated = User.find_by(css_id: "BVALSPORER")
    vso = Organization.find_by(name: "American Legion")
    translation_org = Organization.find_by(name: "Translation")

    FactoryBot.create(:ama_judge_task, assigned_to: judge, appeal: @ama_appeals[0])

    parent = FactoryBot.create(:ama_judge_task, :in_progress, assigned_to: judge, appeal: @ama_appeals[1])
    FactoryBot.create(
      :ama_attorney_task,
      assigned_to: attorney,
      assigned_by: judge,
      parent: parent,
      appeal: @ama_appeals[1]
    ).update(status: :completed)

    parent = FactoryBot.create(:ama_judge_task, :on_hold, assigned_to: judge, appeal: @ama_appeals[2])

    FactoryBot.create(
      :ama_attorney_task,
      :in_progress,
      assigned_to: attorney,
      assigned_by: judge,
      parent: parent,
      appeal: @ama_appeals[2]
    )

    FactoryBot.create(:ama_judge_task, :in_progress, assigned_to: judge, appeal: @ama_appeals[3])

    parent = FactoryBot.create(:ama_judge_task, :on_hold, assigned_to: judge, appeal: @ama_appeals[4])
    child = FactoryBot.create(
      :ama_attorney_task,
      :on_hold,
      assigned_to: attorney,
      assigned_by: judge,
      parent: parent,
      appeal: @ama_appeals[4]
    )
    FactoryBot.create(:ama_colocated_task,
                      appeal: @ama_appeals[4],
                      parent: child,
                      assigned_by: attorney,
                      assigned_to: colocated)

    parent = FactoryBot.create(:ama_judge_task, :in_progress, assigned_to: judge, appeal: @ama_appeals[5])
    FactoryBot.create(:ama_attorney_task,
                      :completed,
                      assigned_to: attorney,
                      assigned_by: judge,
                      parent: parent,
                      appeal: @ama_appeals[5])

    FactoryBot.create(:ama_vso_task, :in_progress, assigned_to: vso, appeal: @appeal_with_vso)

    # Colocated tasks with legacy appeals
    FactoryBot.create(:colocated_task,
                      appeal: LegacyAppeal.find_by(vacols_id: "2096907"),
                      assigned_by: attorney,
                      assigned_to: colocated,
                      action: "schedule_hearing")

    FactoryBot.create(:colocated_task,
                      :in_progress,
                      appeal: LegacyAppeal.find_by(vacols_id: "2226048"),
                      assigned_by: attorney,
                      assigned_to: colocated)

    FactoryBot.create(:colocated_task,
                      :in_progress,
                      appeal: LegacyAppeal.find_by(vacols_id: "2249056"),
                      assigned_by: attorney,
                      assigned_to: colocated)

    FactoryBot.create(:colocated_task,
                      :on_hold,
                      appeal: LegacyAppeal.find_by(vacols_id: "2306397"),
                      assigned_by: attorney,
                      assigned_to: colocated)

    FactoryBot.create(:generic_task, assigned_by: judge, assigned_to: translation_org)
  end

  def create_organizations
    Vso.create(
      name: "American Legion",
      feature: "vso_queue_aml",
      role: "VSO",
      url: "american-legion",
      participant_id: "2452415"
    )
    Vso.create(
      name: "Vietnam Veterans Of America",
      feature: "vso_queue_vva",
      role: "VSO",
      url: "vietnam-veterans-of-america",
      participant_id: "2452415"
    )
    Vso.create(
      name: "Paralyzed Veterans Of America",
      feature: "vso_queue_pva",
      role: "VSO",
      url: "paralyzed-veterans-of-america",
      participant_id: "2452383"
    )

    Organization.create!(name: "Translation", feature: "org_queue_translation", url: "translation")

    Bva.create(name: "Board of Veterans' Appeals")
  end

  def clean_db
    DatabaseCleaner.clean_with(:truncation)
  end

  def seed
    clean_db
    # Annotations and tags don't come from VACOLS, so our seeding should
    # create them in all envs
    create_organizations
    create_annotations
    create_tags
    create_ama_appeals
    create_users
    create_tasks

    return if Rails.env.development?

    # The fake data here is only necessary when we're not running
    # a VACOLS copy locally.
    create_default_users
    create_legacy_appeals(50)
    create_dispatch_tasks(50)
    create_ramp_elections(9)
    create_hearings
    create_api_key
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize

SeedDB.new.seed
