class CreateVbmsDistrobutions < Caseflow::Migration
  def change
    create_table :vbms_distrobutions do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.string :middle_name
      t.string :last_name, null: false
      t.string :participant_id
      t.string :poa_code, null: false
      t.string :claimant_station_oc_jurisdiction, null: false
      t.timestamp :created_at, null: false
      t.timestamp :updated_at
    end
  end
end
