class AddCmpPacketIdToCmpMailPacket < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_reference :cmp_mail_packets, :cmp_mail_packet, foreign_key: true, index: false
    add_index :cmp_mail_packets, :cmp_mail_packet_id, algorithm: :concurrently
  end
end
