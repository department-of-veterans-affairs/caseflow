# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'database_cleaner'

class SeedDB
  def initialize
    @appeals, @tasks, @users = [], [], []
  end

  def create_appeals(number)
    appeals = number.times.map do |i|
      Generators::LegacyAppeal.create(
        vacols_id: "vacols_id#{i}",
        vbms_id: "vbms_id#{i}",
        vacols_record: {
          status: "Remand"
        })
    end

    @appeals.push(*appeals)
    @appeals.push(LegacyAppeal.create(vacols_id: "reader_id1", vbms_id: "reader_id1"))
  end

  def create_users
    User.create(css_id: "BVASCASPER1", station_id: 101, full_name: "Attorney with cases")
    User.create(css_id: "BVASRITCHIE", station_id: 101, full_name: "Attorney no cases")
    User.create(css_id: "BVAAABSHIRE", station_id: 101, full_name: "Judge with hearings and cases")
    User.create(css_id: "BVARERDMAN", station_id: 101, full_name: "Judge has attorneys with cases")
    User.create(css_id: "BVAOFRANECKI", station_id: 101, full_name: "Judge has case to sign")
    User.create(css_id: "BVAJWEHNER", station_id: 101, full_name: "Judge has case to assign no team")
    User.create(css_id: "BVALSPORER", station_id: 101, full_name: "Co-located no cases")

    Functions.grant!("System Admin", users: User.all.pluck(:css_id))
  end

  def create_tasks(number)
    num_appeals = @appeals.length
    tasks = number.times.map do |i|
      establish_claim = EstablishClaim.create(
        appeal: @appeals[i % num_appeals],
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
    5.times do |index|
      task = EstablishClaim.assign_next_to!(@users[3])
      task.start!
      task.review!
      task.complete!(status: :routed_to_arc)
    end

    task = EstablishClaim.assign_next_to!(@users[4])

    # assigning and moving the task to complete for
    # user at index 5
    3.times do |index|
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
    @users.push(User.create(css_id: "Reader", station_id: "405", full_name: "VBMS Station ID maps to multiple VACOLS IDs"))
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

    ["11555555", "12555555"].each do |number|
      RampElection.create!(
        veteran_file_number: number,
        notice_date: 3.weeks.ago
      )
    end
  end

  def create_tags
    DocumentsTag.create(
      tag_id: Generators::Tag.create(text: "Service Connected").id,
      document_id: 1)
    DocumentsTag.create(
      tag_id: Generators::Tag.create(text: "Right Knee").id,
      document_id: 2)
  end

  def create_hearings
    Generators::Hearing.create
  end

  def create_api_key
    ApiKey.new(consumer_name: "PUBLIC", key_string: "PUBLICDEMO123").save!
  end

  def create_beaam_appeals
    FactoryBot.create(
      :appeal,
      advanced_on_docket: true,
      veteran_file_number: "209179363",
      veteran: FactoryBot.create(:veteran),
      request_issues: FactoryBot.build_list(:request_issue, 3, description: "Knee pain")
    )
    FactoryBot.create(
      :appeal,
      veteran_file_number: "767574947",
      veteran: FactoryBot.create(:veteran),
      request_issues: FactoryBot.build_list(:request_issue, 2, description: "PTSD")
    )
    FactoryBot.create(
      :appeal,
      :appellant_not_veteran,
      veteran_file_number: "216979849",
      veteran: FactoryBot.create(:veteran),
      request_issues: FactoryBot.build_list(:request_issue, 1, description: "Tinnitus")
    )
  end

  def clean_db
    DatabaseCleaner.clean_with(:truncation)
  end

  def seed
    clean_db
    # Annotations and tags don't come from VACOLS, so our seeding should
    # create them in all envs
    create_annotations
    create_tags
    create_beaam_appeals
    create_users

    User.create(css_id: "VSO", station_id: 101)

    return if Rails.env.development?

    # The fake data here is only necessary when we're not running
    # a VACOLS copy locally.
    create_default_users
    create_appeals(50)
    create_tasks(50)
    create_ramp_elections(9)
    create_hearings
    create_api_key
  end
end


SeedDB.new.seed
