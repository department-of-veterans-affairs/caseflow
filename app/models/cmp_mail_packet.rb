# frozen_string_literal: true

class CmpMailPacket < ApplicationRecord
  validates :cmp_packet_number,
            :packet_source,
            :packet_uuid,
            :va_dor,
            :veteran_first_name,
            :veteran_id,
            :veteran_last_name,
            :veteran_middle_initial,
            presence: true
end
