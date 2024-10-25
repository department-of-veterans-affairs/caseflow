# frozen_string_literal: true

Events::PersonUpdated::Attributes = Struct.new(
  :first_name,
  :last_name,
  :middle_name,
  :name_suffix,
  :participant_id,
  :ssn,
  :date_of_birth,
  :email_address,
  :date_of_death,
  :file_number,
  :is_veteran,
  keyword_init: true
)
