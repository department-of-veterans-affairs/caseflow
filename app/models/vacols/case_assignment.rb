# frozen_string_literal: true

class VACOLS::CaseAssignment < VACOLS::Record
  include ::LegacyAttorneyCaseReviewDocumentIdValidator

  # :nocov:
  self.table_name = "brieff"

  has_one :staff, foreign_key: :slogid, primary_key: :bfcurloc
  has_one :case_decision, foreign_key: :defolder, primary_key: :bfkey
  has_one :correspondent, foreign_key: :stafkey, primary_key: :bfcorkey

  def added_by
    added_by_name = FullName.new(added_by_first_name,
                                 added_by_middle_name,
                                 added_by_last_name).formatted(:readable_full)

    OpenStruct.new(name: added_by_name, css_id: added_by_css_id.presence || "")
  end

  def assigned_by
    assigned_by_user_id = if assigned_by_css_id
                            User.find_by_css_id_or_create_with_default_station_id(assigned_by_css_id).id
                          end

    OpenStruct.new(
      first_name: assigned_by_first_name,
      last_name: assigned_by_last_name,
      pg_id: assigned_by_user_id,
      css_id: assigned_by_css_id
    )
  end

  def assigned_by_name
    [assigned_by_first_name, assigned_by_last_name].join(" ")
  end

  def written_by_name
    [written_by_first_name, written_by_last_name].join(" ")
  end

  class << self
    def active_cases_for_user(css_id)
      id = connection.quote(css_id.upcase)

      select_assignments.where("staff.sdomainid = #{id}")
    end

    # Valid case assignments must have an associated staff table
    # so we perform an inner join on the staff table.
    # We would like to pull in the associated row in the correspondent
    # table to get the veteran's name, and the associated row in the
    # decass table to get the assigned dates, but these are not mandatory,
    # so we left join on both of them.
    def select_assignments
      select("brieff.bfkey as vacols_id",
             "decass.deassign as date_assigned",
             "decass.dereceive as date_received",
             "decass.decomp as date_completed",
             "decass.dedeadline as date_due",
             "decass.deadtim as created_at",
             "decass.demdtim as updated_at",
             "decass.deatty as attorney_id",
             "brieff.bfddec as signed_date",
             "brieff.bfcorlid as vbms_id",
             "brieff.bfd19 as docket_date",
             "corres.snamef as veteran_first_name",
             "corres.snamemi as veteran_middle_initial",
             "corres.snamel as veteran_last_name",
             "brieff.bfac as bfac",
             "brieff.bfregoff as regional_office_key",
             "folder.tinum as docket_number")
        .joins(<<-SQL)
          LEFT JOIN decass
            ON brieff.bfkey = decass.defolder
          LEFT JOIN corres
            ON brieff.bfcorkey = corres.stafkey
          JOIN staff
            ON brieff.bfcurloc = staff.slogid
          JOIN folder
            ON brieff.bfkey = folder.ticknum
        SQL
    end

    def tasks_for_user(css_id)
      id = connection.quote(css_id.upcase)

      select_tasks.where("s2.sdomainid = #{id}")
    end

    def tasks_for_appeal(appeal_id)
      id = connection.quote(appeal_id)

      select_tasks.where("brieff.bfkey = #{id}")
    end

    def latest_task_for_appeal(appeal_id)
      tasks_for_appeal(appeal_id).max_by(&:created_at)
    end

    # rubocop:disable Metrics/MethodLength
    def select_tasks
      select("brieff.bfkey as vacols_id",
             "brieff.bfcurloc as current_location",
             "brieff.bfcorlid as vbms_id",
             "brieff.bfd19 as docket_date",
             "brieff.bfdloout as assigned_to_location_date",
             "decass.deassign as assigned_to_attorney_date",
             "decass.dereceive as reassigned_to_judge_date",
             "decass.decomp as date_completed",
             "decass.dedocid as document_id",
             "decass.deprod as work_product",
             "decass.deatty as attorney_id",
             "s1.snamef as added_by_first_name",
             "s1.snamemi as added_by_middle_name",
             "s1.snamel as added_by_last_name",
             "s1.sdomainid as added_by_css_id",
             "decass.dedeadline as date_due",
             "decass.deadtim as created_at",
             "decass.demdtim as updated_at",
             "folder.tinum as docket_number",
             "s3.snamef as assigned_by_first_name",
             "s3.snamel as assigned_by_last_name",
             "s3.sdomainid as assigned_by_css_id",
             "s2.sdomainid as assigned_to_css_id",
             "s4.snamef as written_by_first_name",
             "s4.snamel as written_by_last_name")
        .joins(<<-SQL)
          LEFT JOIN decass
            ON brieff.bfkey = decass.defolder
          LEFT JOIN staff s1
            ON decass.deadusr = s1.slogid
          JOIN staff s2
            ON brieff.bfcurloc = s2.slogid
          JOIN folder
            ON brieff.bfkey = folder.ticknum
          LEFT JOIN staff s3
            ON decass.demdusr = s3.slogid
          LEFT JOIN staff s4
            ON decass.deatty = s4.sattyid
        SQL
    end
    # rubocop:enable Metrics/MethodLength

    def exists_for_appeals(vacols_ids)
      conn = connection

      conn.transaction do
        query = <<-SQL
          select BRIEFF.BFKEY, count(DECASS.DEASSIGN) N
          from BRIEFF
          left join DECASS on BRIEFF.BFKEY = DECASS.DEFOLDER
          where BRIEFF.BFKEY in (?)
          group by BRIEFF.BFKEY
        SQL

        result = MetricsService.record("VACOLS: CaseAssignment.exists_for_appeals for #{vacols_ids}",
                                       name: "CaseAssignment.exists_for_appeals",
                                       service: :vacols) do
          conn.exec_query(sanitize_sql_array([query, vacols_ids]))
        end

        result.to_a.reduce({}) do |memo, row|
          memo[(row["bfkey"]).to_s] = (row["n"] > 0)
          memo
        end
      end
    end
  end
  # :nocov:
end
