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

  has_many :cmp_documents, inverse_of: :cmp_mail_packet, dependent: :nullify
end
