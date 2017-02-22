class VACOLS::Note < VACOLS::Record
  class InvalidNoteCode < StandardError; end

  CODE_ACTKEY_MAPPING = {
    remand: 'R'
  }

  def create!(case_record:, text:, note_code:, days_to_complete: 30, days_til_due: 3)
    return unless text
    unless note_code = CODE_ACTKEY_MAPPING[note_code]
      fail InvalidNoteCode
    end

    conn = self.class.connection

    text = conn.quote(text)
    case_id = conn.quote(case_record.bfkey)
    regional_office_key = conn.quote(case_record.bfregoff)
    days_to_complete = conn.quote(days_to_complete)
    note_class = conn.quote(note_class)
    due_date = conn.quote((Time.now + days_til_due.days).to_formatted_s(:vacols_date))
    note_code = conn.qoute(note_code)
    user_id = conn.quote(RequestStore.store[:current_user].regional_office.upcase)

    MetricsService.timer "VACOLS: Note.create! #{bfkey}" do
      conn.execute(<<-SQL)
        INSERT into ASSIGN
          (TSKRQACT, TSKSTAT, TSKDTC, TSKCLASS, TSKATCD, TSKDASSN, TSKDDUE,
            TSKTKNM, TSKSTFAS, TSKTOWN, TSKDCLS, TSKADUSR, TSKADTM)
        VALUES
          (#{text}, 'P', #{days_to_complete}, 'ACTIVE', #{note_type}, SYSDATE, #{due_date},
            #{case_id}, #{regional_office_key}, #{user_id}, #{date_closed}, #{user_id}, SYSDATE)
      SQL
    end
  end
end
