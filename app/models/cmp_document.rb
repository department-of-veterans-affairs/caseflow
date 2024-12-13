# frozen_string_literal: true

class CmpDocument < ApplicationRecord
  belongs_to :cmp_mail_packet, optional: true

  validates :cmp_document_id,
            :cmp_document_uuid,
            :packet_uuid,
            :date_of_receipt,
            presence: true

  validates :vbms_doctype_id, numericality: { only_integer: true }
end
