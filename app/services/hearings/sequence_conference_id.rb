# frozen_string_literal: true

##
# Call Hearings::SequenceConferenceId.next to get a number as a
# string between "0000001" and "9999999" for use as a virtual hearing
# conference ID. When the sequence hits its maximum value of "9999999",
# it will loop back to "0000001".
##
module Hearings::SequenceConferenceId
  SEQUENCE_NAME = "virtual_hearing_conference_id_seq"
  MAXIMUM_VALUE = 9_999_999

  class << self
    def next
      create_sequence_if_not_exists
      result = ActiveRecord::Base.connection.execute("SELECT nextval('#{SEQUENCE_NAME}')")
      format("%07<id>d", id: result.first["nextval"])
    end

    private

    # The sequence is created by a migration, but it isn't recorded in
    # the schema. This means that databases created with db:schema:load
    # won't include the sequence. We call this method before accessing
    # the sequence to make sure it exists.
    def create_sequence_if_not_exists
      ActiveRecord::Base.connection.execute(create_sequence_sql)
    end

    def create_sequence_sql
      "CREATE SEQUENCE IF NOT EXISTS #{SEQUENCE_NAME} "\
        "START WITH 1 "\
        "INCREMENT BY 1 "\
        "MINVALUE 1 "\
        "MAXVALUE #{MAXIMUM_VALUE} "\
        "CYCLE "\
        "CACHE 1;"
    end
  end
end
