class GenerateSystemUserForApiUsage < ActiveRecord::Migration[5.1]
  def up
    User.create(
      station_id: 101, # station id for BVA
      css_id: "APIUSER",
      full_name: "API User"
    )
  end

  def down
    User.where(
      station_id: 101,
      css_id: "APIUSER",
      full_name: "API User"
    ).destroy_all
  end
end
