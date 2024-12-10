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

  validates :va_dor_must_be_a_date

  has_many :cmp_documents, inverse_of: :cmp_mail_packet, dependent: :nullify

  def va_dor_must_be_a_date
    # Use the magic <attribute>_before_type_cast accessor to get the raw value
    before_val = va_dor_before_type_cast

    if before_val.blank?
      errors.add(:va_dor, :blank)
      return
    end

    # For yyyy-mm-dd format:
    # Require non-zero first digit; require the exact number of digits for each.
    if !before_val.is_a?(String) && !/^[1-9]{1}\d{3}-\d{2}-\d{2}$/.match?(before_val.strftime("%Y-%m-%d"))
      errors.add(:va_dor, "date_of_receipt must use the format yyyy-mm-dd")
      return
    end

    if before_val.is_a?(String) && !/^[1-9]{1}\d{3}-\d{2}-\d{2}$/.match?(before_val)
      errors.add(:va_dor, "date_of_receipt must use the format yyyy-mm-dd")
      return
    end
  rescue Date::Error
    errors.add(:va_dor, "date_of_receipt must be a valid date")
  end
end
