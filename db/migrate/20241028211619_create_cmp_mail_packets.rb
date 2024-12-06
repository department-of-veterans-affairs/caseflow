class CreateCmpMailPackets < ActiveRecord::Migration[6.1]
  def change
    create_table :cmp_mail_packets do |t|
      t.string :packet_uuid, null: false
      t.string :cmp_packet_number, null: false
      t.string :packet_source, null: false
      t.datetime :va_dor, null: false
      t.string :veteran_id, null: false
      t.string :veteran_first_name, null: false
      t.string :veteran_middle_initial, null: false
      t.string :veteran_last_name, null: false

      t.timestamps
    end
  end
end
