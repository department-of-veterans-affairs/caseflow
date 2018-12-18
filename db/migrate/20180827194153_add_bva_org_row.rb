class AddBvaOrgRow < ActiveRecord::Migration[5.1]
  def up
    Bva.create(name: "Board of Veterans' Appeals")
  end

  def down
    Bva.where(name: "Board of Veterans' Appeals").delete_all
  end
end
