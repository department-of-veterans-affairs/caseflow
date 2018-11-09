# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require "database_cleaner"
# rubocop:disable Metrics/ClassLength
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
    User.create(css_id: "BVATWARNER", station_id: 101, full_name: "Build Hearing Schedule")
    User.create(css_id: "BVAGWHITE", station_id: 101, full_name: "BVA Dispatch user with cases")

    Functions.grant!("System Admin", users: User.all.pluck(:css_id))

    create_colocated_user
    create_vso_user
    create_org_queue_users
    create_qr_user
    create_mail_team_user
    create_bva_dispatch_user_with_tasks
    create_case_search_only_user
  end

  def create_colocated_user
    user = User.create(css_id: "BVALSPORER", station_id: 101, full_name: "Co-located with cases")
    FactoryBot.create(:staff, :colocated_role, user: user, sdept: "DSP")
  end

  def create_vso_user
    u = User.create(
      css_id: "VSO",
      station_id: 101,
      full_name: "VSO user associated with PVA",
      roles: %w[VSO]
    )
    OrganizationsUser.add_user_to_organization(u, Organization.find_by(name: "Paralyzed Veterans Of America"))
  end

  def create_org_queue_users
    (0..5).each do |n|
      u = User.create!(station_id: 101, css_id: "ORG_QUEUE_USER_#{n}", full_name: "Translation team member")
      translation = Organization.create!(name: "Translation", url: "translation")
      OrganizationsUser.add_user_to_organization(u, translation)
    end
  end

  def create_qr_user
    u = User.create!(station_id: 101, css_id: "QR_USER", full_name: "QR User")
    OrganizationsUser.add_user_to_organization(u, QualityReview.singleton)
  end

  def create_mail_team_user
    u = User.create!(station_id: 101, css_id: "JOLLY_POSTMAN", full_name: "Jolly D. Postman")
    OrganizationsUser.add_user_to_organization(u, MailTeam.singleton)
  end

  def create_bva_dispatch_user_with_tasks
    u = User.find_by(css_id: "BVAGWHITE")
    OrganizationsUser.add_user_to_organization(u, BvaDispatch.singleton)

    3.times do
      root = FactoryBot.create(:root_task)
      FactoryBot.create_list(
        :request_issue,
        [3, 4, 5].sample,
        description: "Kidney problems",
        review_request: root.appeal
      )
      parent = FactoryBot.create(
        :bva_dispatch_task,
        assigned_to: BvaDispatch.singleton,
        parent_id: root.id,
        appeal: root.appeal
      )
      FactoryBot.create(
        :bva_dispatch_task,
        assigned_to: u,
        parent_id: parent.id,
        appeal: parent.appeal
      )
    end
  end

  def create_case_search_only_user
    u = User.create!(station_id: 101, css_id: "CASE_SEARCHER_ONLY", full_name: "Case search access. No Queue access")
    FeatureToggle.enable!(:case_search_home_page, users: [u.css_id])
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
    @appeal_with_vso = FactoryBot.create(
      :appeal,
      claimants: [
        FactoryBot.build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO"),
        FactoryBot.build(:claimant, participant_id: "OTHER_CLAIMANT")
      ],
      veteran_file_number: "701305078",
      docket_type: "direct_review",
      request_issues: FactoryBot.create_list(:request_issue, 3, description: "Head trauma")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      veteran_file_number: "783740847",
      docket_type: "evidence_submission",
      request_issues: FactoryBot.create_list(:request_issue, 3, description: "Knee pain")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      veteran_file_number: "963360019",
      docket_type: "direct_review",
      request_issues: FactoryBot.create_list(:request_issue, 2, description: "PTSD")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "604969679",
      docket_type: "direct_review",
      request_issues: FactoryBot.create_list(:request_issue, 1, description: "Tinnitus")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "228081153",
      docket_type: "evidence_submission",
      request_issues: FactoryBot.create_list(:request_issue, 1, description: "Tinnitus")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "152003980",
      docket_type: "direct_review",
      request_issues: FactoryBot.create_list(:request_issue, 3, description: "PTSD")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "375273128",
      docket_type: "direct_review",
      request_issues: FactoryBot.create_list(:request_issue, 1, description: "Knee pain")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "682007349",
      docket_type: "direct_review",
      request_issues: FactoryBot.create_list(:request_issue, 5, description: "Veteran reports hearing loss in left ear")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "231439628S",
      docket_type: "direct_review",
      request_issues: FactoryBot.create_list(:request_issue, 1, description: "Back pain")
    )
    @ama_appeals << FactoryBot.create(
      :appeal,
      number_of_claimants: 1,
      veteran_file_number: "975191063",
      docket_type: "direct_review",
      request_issues: FactoryBot.create_list(:request_issue, 8, description: "Kidney problems")
    )

    LegacyAppeal.create(vacols_id: "2096907", vbms_id: "228081153S")
    LegacyAppeal.create(vacols_id: "2226048", vbms_id: "213912991S")
    LegacyAppeal.create(vacols_id: "2249056", vbms_id: "608428712S")
    LegacyAppeal.create(vacols_id: "2306397", vbms_id: "779309925S")
  end

  def create_root_task(appeal)
    FactoryBot.create(:root_task, appeal: appeal)
  end

  def create_task_at_judge_assignment(appeal, judge)
    FactoryBot.create(:ama_judge_task,
                      assigned_to: judge,
                      appeal: appeal,
                      parent: create_root_task(appeal))
  end

  def create_task_at_judge_review(appeal, judge, attorney)
    parent = FactoryBot.create(:ama_judge_task,
                               :in_progress,
                               assigned_to: judge,
                               appeal: appeal,
                               parent: create_root_task(appeal))
    child = FactoryBot.create(
      :ama_attorney_task,
      assigned_to: attorney,
      assigned_by: judge,
      parent: parent,
      appeal: appeal
    )
    child.update(status: :completed)
    FactoryBot.create(:attorney_case_review, task_id: child.id)
  end

  def create_task_at_colocated(appeal, judge, attorney, colocated)
    parent = FactoryBot.create(
      :ama_judge_task,
      :on_hold,
      assigned_to: judge,
      appeal: appeal,
      parent: create_root_task(appeal)
    )

    child = FactoryBot.create(
      :ama_attorney_task,
      :on_hold,
      assigned_to: attorney,
      assigned_by: judge,
      parent: parent,
      appeal: appeal
    )

    FactoryBot.create(:ama_colocated_task,
                      appeal: appeal,
                      parent: child,
                      assigned_by: attorney,
                      assigned_to: colocated)
  end

  def create_task_at_attorney_review(appeal, judge, attorney)
    parent = FactoryBot.create(
      :ama_judge_task,
      :on_hold,
      assigned_to: judge,
      appeal: appeal,
      parent: create_root_task(appeal)
    )

    FactoryBot.create(
      :ama_attorney_task,
      :in_progress,
      assigned_to: attorney,
      assigned_by: judge,
      parent: parent,
      appeal: appeal
    )
  end

  def create_tasks
    attorney = User.find_by(css_id: "BVASCASPER1")
    judge = User.find_by(css_id: "BVAAABSHIRE")
    colocated = User.find_by(css_id: "BVALSPORER")
    vso = Organization.find_by(name: "American Legion")
    translation_org = Organization.find_by(name: "Translation")

    create_task_at_judge_assignment(@ama_appeals[0], judge)
    create_task_at_judge_assignment(@ama_appeals[1], judge)
    create_task_at_judge_assignment(@ama_appeals[2], judge)
    create_task_at_judge_assignment(@ama_appeals[3], judge)
    create_task_at_judge_review(@ama_appeals[4], judge, attorney)
    create_task_at_judge_review(@ama_appeals[5], judge, attorney)
    create_task_at_colocated(@ama_appeals[6], judge, attorney, colocated)
    create_task_at_attorney_review(@ama_appeals[7], judge, attorney)
    create_task_at_attorney_review(@ama_appeals[8], judge, attorney)

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

    FactoryBot.create_list(:generic_task, 5, assigned_by: judge, assigned_to: translation_org)
  end

  def create_vsos
    Vso.create(
      name: "American Legion",
      role: "VSO",
      url: "american-legion",
      participant_id: "2452415"
    )
    Vso.create(
      name: "Vietnam Veterans Of America",
      role: "VSO",
      url: "vietnam-veterans-of-america",
      participant_id: "2452415"
    )
    Vso.create(
      name: "Paralyzed Veterans Of America",
      role: "VSO",
      url: "pva",
      participant_id: "2452383"
    )
  end

  def clean_db
    DatabaseCleaner.clean_with(:truncation)
  end

  def setup_dispatch
    CreateEstablishClaimTasksJob.perform_now
    Timecop.freeze(Date.yesterday) do
      # Tasks prepared on today's date will not be picked up
      Dispatch::Task.all.each(&:prepare!)
      # Appeal decisions (decision dates) for partial grants have to be within 3 days
      CSV.foreach(Rails.root.join("local/vacols", "cases.csv"), headers: true) do |row|
        row_hash = row.to_h
        if %w[amc_full_grants remands_ready_for_claims_establishment].include?(row_hash["vbms_key"])
          VACOLS::Case.where(bfkey: row_hash["vacols_id"]).first.update(bfddec: Time.zone.today)
        end
      end
    end
  rescue AASM::InvalidTransition
    Rails.logger.info("Taks prepare job skipped - tasks were already prepared...")
  end

  def create_previously_held_hearing_data
    user = User.find_by_css_id("BVAAABSHIRE")
    appeal = LegacyAppeal.find_or_create_by(vacols_id: "3617215", vbms_id: "994806951S")

    return if ([appeal.type] - ["Post Remand", "Original"]).empty? &&
              appeal.hearings.map(&:disposition).include?(:held)

    FactoryBot.create(:case_hearing, :disposition_held, user: user, folder_nr: appeal.vacols_id)
  end

  def seed
    clean_db
    # Annotations and tags don't come from VACOLS, so our seeding should
    # create them in all envs
    create_vsos
    create_annotations
    create_tags
    create_ama_appeals
    create_users
    create_tasks

    setup_dispatch
    create_previously_held_hearing_data

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
# rubocop:enable Metrics/ClassLength

SeedDB.new.seed
