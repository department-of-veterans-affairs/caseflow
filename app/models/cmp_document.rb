# frozen_string_literal: true

class CmpDocument < ApplicationRecord
  belongs_to :cmp_mail_packet, optional: true

  validates :cmp_document_id,
            :cmp_document_uuid,
            :date_of_receipt,
            :packet_uuid,
            :vbms_doctype_id,
            presence: true

  validates :vbms_doctype_id, numericality: { only_integer: true }

  validate :date_of_receipt_must_be_a_date

  def date_of_receipt_must_be_a_date
    # Use the magic <attribute>_before_type_cast accessor to get the raw value
    before_val = date_of_receipt_before_type_cast

    if before_val.blank?
      errors.add(:date_of_receipt, :blank)
      return
    end

    # Validates dateOfReceipt is in yyyy-mm-dd (csv_date) format.
    DateTime.strptime(before_val, Date::DATE_FORMATS[:csv_date])
  rescue Date::Error
    errors.add(:date_of_receipt, "date_of_receipt must use the format yyyy-mm-dd")
  end
end
