class VACOLS::CaseIssue < VACOLS::Record
  self.table_name = "vacols.issues"
  self.sequence_name = "vacols.issseq"
  self.primary_key = "isskey"

  COLUMN_NAMES = {
    vacols_id: :isskey,
    vacols_sequence_id: :issseq,
    program: :issprog,
    issue: :isscode,
    level_1: :isslev1,
    level_2: :isslev2,
    level_3: :isslev3,
    added_by: :issaduser,
    note: :issdesc
  }.freeze

  validates :isskey, :issseq, :issprog, :isscode, :issaduser, :issadtime, presence: true, on: :create

  # :nocov:
  def remand_clone_attributes
    slice(:issprog, :isscode, :isslev1, :isslev2, :isslev3, :issdesc, :issgr)
  end

  # rubocop:disable MethodLength

  # Issues can be labeled by looking up the combination of ISSPROG,
  # ISSCODE, ISSLEV1, ISSLEV2, and ISSLEV3 in the ISSREF table.
  # However, any one of ISSLEV1-3 may be a four-digit diagnostic code,
  # shown in ISSREF.LEV1-3_CODE as '##'. These codes must be looked up
  # in VFTYPES.FTKEY, where the diagnostic code is prefixed with 'DG'.
  # This query matches each ISSUE table code with the appropriate label,
  # either from the ISSREF or VFTYPES table.
  def self.descriptions(vacols_ids)
    conn = connection

    query = <<-SQL
      select
        ISSUES.ISSKEY,
        ISSUES.ISSSEQ,
        ISSUES.ISSDC,
        ISSUES.ISSDCLS,
        ISSUES.ISSDESC,
        ISSUES.ISSPROG,
        ISSUES.ISSCODE,
        ISSUES.ISSLEV1,
        ISSUES.ISSLEV2,
        ISSUES.ISSLEV3,
        ISSREF.PROG_DESC ISSPROG_LABEL,
        ISSREF.ISS_DESC ISSCODE_LABEL,
        case when ISSUES.ISSLEV1 is not null then
          case when ISSREF.LEV1_CODE = '##' then
            VFTYPES.FTDESC else ISSREF.LEV1_DESC
          end
        end ISSLEV1_LABEL,
        case when ISSUES.ISSLEV2 is not null then
          case when ISSREF.LEV2_CODE = '##' then
            VFTYPES.FTDESC else ISSREF.LEV2_DESC
          end
        end ISSLEV2_LABEL,
        case when ISSUES.ISSLEV3 is not null then
          case when ISSREF.LEV3_CODE = '##' then
            VFTYPES.FTDESC else ISSREF.LEV3_DESC
          end
        end ISSLEV3_LABEL

      from ISSUES

      inner join ISSREF
        on ISSUES.ISSPROG = ISSREF.PROG_CODE
        and ISSUES.ISSCODE = ISSREF.ISS_CODE
        and (ISSUES.ISSLEV1 is null
          or ISSREF.LEV1_CODE = '##'
          or ISSUES.ISSLEV1 = ISSREF.LEV1_CODE)
        and (ISSUES.ISSLEV2 is null
          or ISSREF.LEV2_CODE = '##'
          or ISSUES.ISSLEV2 = ISSREF.LEV2_CODE)
        and (ISSUES.ISSLEV3 is null
          or ISSREF.LEV3_CODE = '##'
          or ISSUES.ISSLEV3 = ISSREF.LEV3_CODE)

      left join VFTYPES
        on VFTYPES.FTTYPE = 'DG'
        and ((ISSREF.LEV1_CODE = '##' and 'DG' || ISSUES.ISSLEV1 = VFTYPES.FTKEY)
          or (ISSREF.LEV2_CODE = '##' and 'DG' || ISSUES.ISSLEV2 = VFTYPES.FTKEY)
          or (ISSREF.LEV3_CODE = '##' and 'DG' || ISSUES.ISSLEV3 = VFTYPES.FTKEY))

      where ISSUES.ISSKEY IN (?)
    SQL

    issues_result = MetricsService.record("VACOLS: CaseIssue.descriptions for #{vacols_ids}",
                                          name: "CaseIssue.descriptios",
                                          service: :vacols) do
      conn.exec_query(sanitize_sql_array([query, vacols_ids]))
    end

    issues_result.to_hash.reduce({}) do |memo, result|
      issue_key = result["isskey"].to_s
      memo[issue_key] = (memo[issue_key] || []) << result
      memo
    end
  end
  # rubocop:enable MethodLength

  def self.create_issue!(issue_hash)
    attrs = issue_hash.each_with_object({}) { |(k, v), result| result[COLUMN_NAMES[k]] = v }

    MetricsService.record("VACOLS: CaseIssue.create_issue! for #{issue_hash[:vacols_id]}",
                          service: :vacols,
                          name: "CaseIssue.create_issue") do
      create!(attrs.merge(issadtime: VacolsHelper.local_time_with_utc_timezone,
                          issseq: generate_sequence_id(issue_hash[:vacols_id])))
    end
  end

  def self.generate_sequence_id(vacols_id)
    return unless vacols_id
    descriptions(vacols_id)[vacols_id].count + 1
  end
  # :nocov:
end
