class VACOLS::Note < VACOLS::Record
  self.table_name = "vacols.assign"
  self.primary_key = "tasknum"

  class InvalidNoteCodeError < StandardError; end
  class InvalidNotelengthError < StandardError; end
  class TextRequiredError < StandardError; end

  CODE_ACTKEY_MAPPING = {
    other: "BVA30"
  }.freeze

  # simple alias for more concise code
  def self.conn
    connection
  end

  # VACOLS does not auto-generate primary keys. Instead we must manually create one.
  # Below is the logic currently used by VACOLS apps to generate note IDs
  # NOTE: For consistency, we should keep this logic in sync with the VACOLS applets
  def self.generate_primary_key(bfkey)
    case_id = conn.quote(bfkey)

    query = <<-SQL
      SELECT count(*) as count
      FROM ASSIGN
      WHERE TSKTKNM = #{case_id}
    SQL

    count_res = MetricsService.record "VACOLS: Note.generate_primary_key #{bfkey}" do
      conn.exec_query(query)
    end
    count = count_res.to_a.first["count"]

    "#{bfkey}D#{count + 1}"
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def self.create!(case_record:, text:, note_code: :other, days_to_complete: 30, days_til_due: 30)
    validate!(text: text, note_code: note_code)

    text = conn.quote(text)
    case_id = conn.quote(case_record.bfkey)
    regional_office_key = conn.quote(case_record.bfregoff)
    days_to_complete = conn.quote(days_to_complete)
    due_date = conn.quote(Time.zone.now + days_til_due.days)
    note_code = conn.quote(CODE_ACTKEY_MAPPING[note_code])
    user_id = conn.quote(RequestStore.store[:current_user].regional_office.upcase)
    primary_key = generate_primary_key(case_record.bfkey)
    quoted_primary_key = conn.quote(primary_key)

    query = <<-SQL
      INSERT into ASSIGN
        (TASKNUM, TSKRQACT, TSKSTAT, TSKDTC, TSKCLASS, TSKACTCD, TSKDASSN,
         TSKDDUE, TSKTKNM, TSKSTFAS, TSKSTOWN, TSKADUSR, TSKADTM)
      VALUES
        (#{quoted_primary_key}, #{text}, 'P', #{days_to_complete}, 'ACTIVE', #{note_code}, SYSDATE,
         #{due_date}, #{case_id}, #{regional_office_key}, #{user_id}, #{user_id}, SYSDATE)
    SQL

    MetricsService.record "VACOLS: Note.create! #{case_id}" do
      conn.execute(query)
    end

    primary_key
  end

  def self.validate!(text:, note_code:)
    fail(TextRequiredError) unless text
    fail(InvalidNotelengthError) if text.length > 280
    fail InvalidNoteCodeError unless CODE_ACTKEY_MAPPING[note_code]
  end
end
