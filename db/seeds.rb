# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

class SeedDB
  def initialize
    @appeals, @tasks, @users = [], [], []
  end

  def create_appeals(number)
    appeals = number.times.map do |i|
      Appeal.create(
        vacols_id: "vacols_id#{i}",
        vbms_id: "vbms_id#{i}"
        )
    end
    @appeals.push(*appeals)
  end

  def create_users(number, deterministic = true)
    users = number.times.map do |i|
      length = VACOLS::RegionalOffice::STATIONS.length
      station_index = deterministic ? (i % length) : (rand(length))
      User.create(
        station_id: VACOLS::RegionalOffice::STATIONS.keys[station_index],
        css_id: "css_#{i}"
        )
    end

    @users.push(*users)
  end

  def create_tasks(number)
    num_appeals = @appeals.length
    num_users = @users.length

    tasks = number.times.map do |i|
      establish_claim = EstablishClaim.create(
        appeal: @appeals[i % num_appeals]
        )
      if i % 4 > 0
        establish_claim.assign(@users[i % num_users])
      end

      if i % 4 > 1
        establish_claim.started_at = 1.day.ago
      end

      if i % 4 > 2
        establish_claim.completed_at = 0.day.ago
        if i % 3 == 0
          establish_claim.completion_status = 1
        end
      end
      establish_claim.save
    end

    @tasks.push(*tasks)
  end

  def create_default_users
    @users.push(User.create(css_id: "ANNE MERICA", station_id: "283"))
    @users.push(User.create(css_id: "Establish Claim", station_id: "283"))
    @users.push(User.create(css_id: "Establish Claim, Manage Claim Establishment", station_id: "283"))
    @users.push(User.create(css_id: "Certify Appeal", station_id: "283"))
  end

  def seed
    create_default_users
    create_appeals(50)
    create_users(2)
    create_tasks(50)
  end
end


SeedDB.new.seed
