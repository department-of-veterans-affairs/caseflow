# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

class SeedDB
  def create_appeals(number)
    @appeals = number.times.map do |i|
      Appeal.create(vacols_id: "vacols_id#{i}",
                    vbms_id: "vbms_id#{i}")
    end
  end

  def create_users(number, deterministic = true)
    @users = number.times.map do |i|
      length = VACOLS::RegionalOffice::STATIONS.length
      station_index = deterministic ? (i % length) : (rand(length))
      User.create(station_id: VACOLS::RegionalOffice::STATIONS.keys[station_index],
                  css_id: "css_#{i}")
    end
  end

  def create_tasks(number)
    numAppeals = @appeals.length
    numUsers = @users.length
    @tasks = number.times.map do |i|
      CreateEndProduct.create(appeal: @appeals[i % numAppeals],
                              user: @users[i % numUsers])
    end
  end

  def seed
    create_appeals(50)
    create_users(3)
    create_tasks(50)
  end
end


SeedDB.new.seed