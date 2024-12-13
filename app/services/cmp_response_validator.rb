# frozen_string_literal: true

class CmpResponseValidator
  def validate_cmp_document_request(api_request)
    date_field_must_be_a_valid_date(api_request[:date_of_receipt])
  end

  def validate_cmp_mail_packet_request(api_request)
    date_field_must_be_a_valid_date(api_request[:va_dor])
  end

  private

  def date_field_must_be_a_valid_date(date_field)
    if date_field.blank?
      Rails.logger.error("blank")
      return false
    end
    # For yyyy-mm-dd format:
    # Require non-zero first digit; require the exact number of digits for each.
    if !/^[1-9]{1}\d{3}-\d{2}-\d{2}$/.match?(date_field)
      Rails.logger.error("invalid match regex")
      return false
    end

    begin
      # Validates dateOfReceipt is in yyyy-mm-dd (csv_date) format and is parsable to a valid date
      DateTime.strptime(date_field, Date::DATE_FORMATS[:csv_date])
    rescue Date::Error
      Rails.logger.error("can't parse date")
      false
    end

    true
  end
end
