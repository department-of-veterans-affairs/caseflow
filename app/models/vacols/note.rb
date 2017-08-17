class VACOLS::Note < VACOLS::Record
  self.table_name = "vacols.assign"
  self.primary_key = "tasknum"

  class InvalidNoteCodeError < StandardError; end
  class InvalidNotelengthError < StandardError; end

  CODE_ACTKEY_MAPPING = {
    other: "BVA30",
    A: "A",
    B: "B",
    B1: "B1"
  }.freeze

  class << self
    # simple alias for more concise code
    def conn
      connection
    end

    # VACOLS does not auto-generate primary keys. Instead we must manually create one.
    # Below is the logic currently used by VACOLS apps to generate note IDs
    # NOTE: For consistency, we should keep this logic in sync with the VACOLS applets
    def generate_primary_key(bfkey)
      case_id = conn.quote(bfkey)

      query = <<-SQL
        SELECT count(*) as count
        FROM ASSIGN
        WHERE TSKTKNM = #{case_id}
      SQL

      count_res = MetricsService.record("VACOLS: Note.generate_primary_key #{bfkey}",
                                        service: :vacols,
                                        name: "generate_primary_key") do
        conn.exec_query(query)
      end
      count = count_res.to_a.first["count"]

      "#{bfkey}D#{count + 1}"
    end

    # rubocop:disable MethodLength
    def create!(note)
      validate!(note)

      primary_key = generate_primary_key(note[:case_id])

      MetricsService.record("VACOLS: Note.create! #{note[:case_id]}",
                            service: :vacols,
                            name: "create") do
        VACOLS::Note.create(
          tasknum: primary_key,
          tskrqact: note[:text],
          tskstat: "P",
          tskdtc: note[:days_to_complete],
          tskclass: "ACTIVE",
          tskactcd: CODE_ACTKEY_MAPPING[note[:code]],
          tskdassn: VacolsHelper.local_time_with_utc_timezone,
          tskddue: Time.zone.now + note[:days_til_due].days,
          tsktknm: note[:case_id],
          tskstfas: note[:assigned_to],
          tskstown: note[:user_id],
          tskadusr: note[:user_id],
          tskadtm: VacolsHelper.local_time_with_utc_timezone
        )
      end
      primary_key
    end
    # rubocop:enable MethodLength

    def find_active_by_user_and_type(note)
      VACOLS::Note.find_by(
        tsktknm: note[:case_id],
        tskstown: note[:user_id],
        tskadusr: note[:user_id],
        tskactcd: CODE_ACTKEY_MAPPING[note[:code]],
        tskstat: "P"
      )
    end

    def delete!(note)
      record = find_active_by_user_and_type(note)
      return unless record
      MetricsService.record("VACOLS: Note.delete! #{note[:case_id]}",
                            service: :vacols,
                            name: "delete") do
        record.delete
      end
    end

    def update_or_create!(note)
      # First check if the query already exists. Search for:
      # 1) active diary, 2) of the same type, 3) owned by the same person.
      # If not found, create a new note
      record = find_active_by_user_and_type(note)
      return create!(note) unless record

      VacolsHelper.validate_presence(note, [:days_to_complete, :days_til_due])

      record.update!(tskmdtm: VacolsHelper.local_time_with_utc_timezone,
                     tskdtc: note[:days_to_complete],
                     tskddue: Time.zone.now + note[:days_til_due].days)
    end

    # ACSPARE1 keeps track who should be assigned diaries of a given type (based on the note_code)
    def assignee(note_code)
      VACOLS::Actcode.find_by(actckey: CODE_ACTKEY_MAPPING[note_code]).try(:acspare1)
    end

    def default_number_of_days(note_code)
      VACOLS::Actcode.find_by(actckey: CODE_ACTKEY_MAPPING[note_code]).try(:actcdtc)
    end

    def validate!(note)
      required_fields = [:days_to_complete, :days_til_due, :code, :user_id, :assigned_to, :case_id, :text]
      VacolsHelper.validate_presence(note, required_fields)
      fail(InvalidNotelengthError) if note[:text].length > 280
      fail(InvalidNoteCodeError) unless CODE_ACTKEY_MAPPING[note[:code]]
    end
  end
end
