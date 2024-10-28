# frozen_string_literal: true

class CmpDocument < ApplicationRecord
  validates :cmp_document_id,
            :cmp_document_uuid,
            :date_of_receipt,
            :packet_uuid,
            :vbms_doctype_id,
            presence: true

  belongs_to :cmp_mail_packet, optional: true
end
