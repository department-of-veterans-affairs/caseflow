module Seeds
  class Defaults
    def initialize
      @legacy_appeals = []
      @tasks = []
      @users = []
    end

    def seed!
      return # currently not used, preserved till we can delete or fix.

      # The fake data here is only necessary when we're not running
      # a VACOLS copy locally.
      create_default_users
      create_legacy_appeals(50)
      create_dispatch_tasks(50)
      create_ramp_elections(9)
      create_api_key
    end
  
    def create_default_users
      @users.push(
        User.create(
          css_id: "Reader",
          station_id: "405",
          full_name: "Padma VBMSStationIDMapsToMultipleVACOLSIDs Brannon"
        )
      )
      @users.push(User.create(css_id: "Invalid Role", station_id: "283", full_name: "Cave InvalidRole Johnson"))
      @users.push(User.create(css_id: "Establish Claim", station_id: "283", full_name: "Jane EstablishClaim Smith"))
      @users.push(User.create(css_id: "Establish Claim 2", station_id: "405", full_name: "Carole EstablishClaim Johnson"))
      @users.push(User.create(css_id: "Manage Claim Establishment", station_id: "283", full_name: "John ManageClaimEstablishment Doe"))
      @users.push(User.create(css_id: "Certify Appeal", station_id: "283", full_name: "John CertifyAppeal Smith"))
      @users.push(User.create(css_id: "System Admin", station_id: "283", full_name: "Angelina SystemAdmin Smith"))
      @users.push(User.create(css_id: "Reader 2", station_id: "283", full_name: "Angelina ReaderAccess Smith"))
      @users.push(User.create(css_id: "Hearing Prep", station_id: "283", full_name: "Lauren HearingPrep Roth"))
      @users.push(User.create(css_id: "Mail Intake", station_id: "283", full_name: "Kwame MailIntake Nkrumah"))
      @users.push(User.create(css_id: "Admin Intake", station_id: "283", full_name: "Ash AdminIntake Ketchum"))
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
        binding.pry
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
  
    def create_api_key
      ApiKey.new(consumer_name: "PUBLIC", key_string: "PUBLICDEMO123").save!
    end
  end
end
