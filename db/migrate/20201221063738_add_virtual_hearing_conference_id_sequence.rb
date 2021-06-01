##
# Creates a sequence for virtual hearing conference IDs. The sequence
# will go from 1 to 9999999 and then start again at 1.
##
class AddVirtualHearingConferenceIdSequence < Caseflow::Migration
  def up
    safety_assured do
      execute <<-SQL
        CREATE SEQUENCE IF NOT EXISTS virtual_hearing_conference_id_seq
          START WITH 1
          INCREMENT BY 1
          MINVALUE 1
          MAXVALUE 9999999
          CYCLE
          CACHE 1;
      SQL
    end
  end

  def down
    safety_assured do
      execute <<-SQL
        DROP SEQUENCE IF EXISTS virtual_hearing_conference_id_seq;
      SQL
    end
  end
end
