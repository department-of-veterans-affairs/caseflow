# frozen_string_literal: true

class CmpDocument < ApplicationRecord
  validates :cmp_document_id,
            :cmp_document_uuid,
            :date_of_receipt,
            :packet_uuid,
            :vbms_doctype_id,
            presence: true

  belongs_to :cmp_mail_packet, optional: true

  validate :date_of_receipt_must_be_a_date, on: [:create, :update]

  def date_of_receipt_must_be_a_date
    date_of_receipt&.to_date || errors.add(:date_of_receipt, :blank)
  rescue Date::Error
    errors.add(:date_of_receipt, :invalid)
  end
end
