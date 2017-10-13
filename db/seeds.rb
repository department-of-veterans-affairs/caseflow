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
      Generators::Appeal.create(
        vacols_id: "vacols_id#{i}",
        vbms_id: "vbms_id#{i}"
        )
    end

    @appeals.push(*appeals)
    @appeals.push(Appeal.create(vacols_id: "reader_id1", vbms_id: "reader_id1"))
  end

  def create_users(number, deterministic = true)
    users = number.times.map do |i|
      length = VACOLS::RegionalOffice::STATIONS.length
      station_index = deterministic ? (i % length) : (rand(length))
      User.create(
        station_id: VACOLS::RegionalOffice::STATIONS.keys[station_index],
        css_id: "css_#{i}",
        full_name: "name_#{i}",
        email: "test#{i}@example.com"
        )
    end

    @users.push(*users)
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

    # Give each user a task in a different state
    tasks[0].assign!(@users[0])

    tasks[1].assign!(@users[1])
    tasks[1].start!

    tasks[2].assign!(@users[2])
    tasks[2].start!
    tasks[2].review!
    tasks[2].complete!(status: :routed_to_arc)

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
  end

  def create_annotations
    Generators::Annotation.create(comment: "Hello World!", document_id: 1, x: 300, y: 400)
    Generators::Annotation.create(comment: "This is an example comment", document_id: 2)
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

  def clean_db
    DatabaseCleaner.clean_with(:truncation)
  end

  def seed
    clean_db
    create_default_users
    create_appeals(50)
    create_users(3)
    create_tasks(50)
    create_annotations
    create_tags
    create_hearings
    create_api_key
  end
end


SeedDB.new.seed
