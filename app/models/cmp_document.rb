# frozen_string_literal: true

class CmpDocument < ApplicationRecord
  belongs_to :cmp_mail_packet, optional: true

  validates :cmp_document_id,
            :cmp_document_uuid,
            :packet_uuid,
            presence: true

  validates :vbms_doctype_id, numericality: { only_integer: true }

  validate :date_of_receipt_must_be_a_date

  def date_of_receipt_must_be_a_date
    # Use the magic <attribute>_before_type_cast accessor to get the raw value
    before_val = date_of_receipt_before_type_cast
    check_value_present(before_val)
    check_date_format(before_val)
  rescue Date::Error
    errors.add(:date_of_receipt, "date_of_receipt must be a valid date")
  end

  private

  def check_value_present(date)
    if date.blank?
      errors.add(:date_of_receipt, :blank)
    end
  end

  def check_date_format(date)
    # For yyyy-mm-dd format:
    # Require non-zero first digit; require the exact number of digits for each.
    if !date.is_a?(String) && !/^[1-9]{1}\d{3}-\d{2}-\d{2}$/.match?(date.strftime("%Y-%m-%d"))
      errors.add(:date_of_receipt, "date_of_receipt must use the format yyyy-mm-dd")
    elsif date.is_a?(String) && !/^[1-9]{1}\d{3}-\d{2}-\d{2}$/.match?(date)
      errors.add(:date_of_receipt, "date_of_receipt must use the format yyyy-mm-dd")
    end
  end
end
