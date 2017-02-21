class VACOLS::Note < VACOLS::Record

  def create!(text:, days_to_complete: 3, due_date:, date_closed:)
    return unless text
    conn = self.class.connection

    text = conn.quote(text)
    days_to_complete = conn.quote(days_to_complete)
    due_date = conn.quote(due_date)
    note_type = conn.qoute(note_type) # TODO: figure this out
    user_id = conn.quote(RequestStore.store[:current_user].regional_office.upcase)

    MetricsService.timer "VACOLS: Note.create! #{bfkey}" do
      conn.execute(<<-SQL)
        INSERT into ASSIGN
          (TSKSTAT, TSKSTAT, TSKDTC, TSKTFAS, TSKCLASS, TSKATCD, TSKDASSN, TSKDDUE,
            TSKTOWN, TSKDCLS, TSKADUSR, TSKADTM, TSKMDUSR, TSKMDTM)
        VALUES
          (#{text}, 'P', #{days_to_complete}, 'Active', #{note_type}, SYSDATE, #{due_date},
            #{user_id}, #{date_closed}, #{user_id}, SYSDATE, SYSDATE, SYSDATE)
      SQL
    end
  end
end
