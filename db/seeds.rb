# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

class SeedDB
  def createAppeals(number)
    @appeals = number.times.map do |i|
      Appeal.create(
        vacols_id: "vacols_id#{i}",
        vbms_id: "vbms_id#{i}"
        )
    end
  end

  def createUsers(number, deterministic = true)
    @users = number.times.map do |i|
      length = VACOLS::RegionalOffice::STATIONS.length
      station_index = deterministic ? (i % length) : (rand(length))
      User.create(
        station_id: VACOLS::RegionalOffice::STATIONS.keys[station_index],
        css_id: "css_#{i}"
        )
    end
  end

  def createTasks(number)
    numAppeals = @appeals.length
    numUsers = @users.length
    @tasks = number.times.map do |i|
      endProduct = CreateEndProduct.create(
        appeal: @appeals[i % numAppeals], 
        user: @users[i % numUsers]
        )
      if i % 4 > 0
        endProduct.assigned_at = 2.day.ago
      end
      if i % 4 > 1
        endProduct.started_at = 1.day.ago
      end
      if i % 4 > 2
        endProduct.completed_at = 0.day.ago
        if i % 3 == 0
          endProduct.status = 1
        end
      end
      endProduct.save
    end
  end

  def seed
    createAppeals(50)
    createUsers(27)
    createTasks(50)
  end
end


SeedDB.new.seed