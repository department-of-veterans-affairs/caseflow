class VACOLS::Note < VACOLS::Record
  self.table_name = "vacols.assign"
  self.primary_key = "tasknum"
  self.sequence_name = "vacols.tasknumseq"

  class InvalidNoteCode < StandardError; end

  CODE_ACTKEY_MAPPING = {
    remand: 'R'
  }

  def self.create!(case_record:, text:, note_code:, days_to_complete: 30, days_til_due: 30)
    return unless text
    unless note_code = CODE_ACTKEY_MAPPING[note_code]
      fail InvalidNoteCode
    end

    conn = connection

    text = conn.quote(text)
    case_id = conn.quote(case_record.bfkey)
    regional_office_key = conn.quote(case_record.bfregoff)
    days_to_complete = conn.quote(days_to_complete)
    note_class = conn.quote(note_class)
    due_date = conn.quote(Time.now + days_til_due.days)
    note_code = conn.quote(note_code)
    user_id = conn.quote(RequestStore.store[:current_user].regional_office.upcase)

    count_query = MetricsService.timer "VACOLS: Note.create! #{case_id}: count" do
      conn.exec_query(<<-SQL)
        SELECT count(*) as count
        FROM ASSIGN
        WHERE TSKTKNM = #{case_id}
      SQL
    end
    count = count_query.to_a.first["count"]

    # VACOLS does not auto-generate primary keys. Instead we must manually create one.
    # Below is the logic currently used by VACOLS apps to generate note IDs
    note_primary_key = conn.quote("#{case_record.bfkey}D#{count + 1}")

    MetricsService.timer "VACOLS: Note.create! #{case_id}: insert" do
      conn.exec_query(<<-SQL)
        INSERT into ASSIGN
          (TASKNUM, TSKRQACT, TSKSTAT, TSKDTC, TSKCLASS, TSKACTCD, TSKDASSN,
            TSKDDUE, TSKTKNM, TSKSTFAS, TSKSTOWN, TSKADUSR, TSKADTM)
        VALUES
          (#{note_primary_key}, #{text}, 'P', #{days_to_complete}, 'ACTIVE', #{note_code}, SYSDATE,
            #{due_date}, #{case_id}, #{regional_office_key}, #{user_id}, #{user_id}, SYSDATE)
      SQL
    end
  end
end
