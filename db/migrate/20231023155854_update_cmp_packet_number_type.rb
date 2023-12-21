class UpdateCmpPacketNumberType < Caseflow::Migration
  def up
    safety_assured do
      change_column :correspondences, :cmp_packet_number, 'bigint USING CAST(cmp_packet_number AS bigint)'
    end
  end

  def down
    safety_assured do
      change_column :correspondences, :cmp_packet_number, 'character varying USING CAST(cmp_packet_number AS character varying)'
    end
  end
end
