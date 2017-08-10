class UnpreparedDenialsReport < Report
  def self.output_filename
    "unprepared_denials"
  end

  def self.table_columns
    [
      "VACOLS ID",
      "File No",
      "First",
      "Last",
      "Decision Date"
    ]
  end

  def self.table_row(appeal)
    [
      appeal.vacols_id,
      appeal.sanitized_vbms_id,
      appeal.veteran_first_name,
      appeal.veteran_last_name,
      appeal.decision_date
    ]
  end

  JOIN_ISSUE_COUNT = "
    inner join
    (
      select ISSKEY,

      count(case when ISSDC = '3' then 1 end) ISSUE_CNT_REMAND,
      count(case when
      (
        ISSDC = '1' and not
          (
            ISSPROG = '02' and
            ISSCODE = '15' and
            ISSLEV1 = '04'
          )
        )
        then 1 end) ISSUE_CNT_ALLOWED

      from ISSUES
      group by ISSKEY
    )
    on ISSKEY = BFKEY
  ".freeze

  def find_records
    VACOLS::Case.joins(:folder, :correspondent, JOIN_ISSUE_COUNT).where(%{
      BFDDEC >= ?
      and BFDC in ('1', '4')
      and BFMPRO = 'HIS'
      and TIVBMS = 'Y'
      and ISSUE_CNT_ALLOWED = 0
      and ISSUE_CNT_REMAND = 0
    }, 120.days.ago)
  end

  def load_record(case_record)
    AppealRepository.build_appeal(case_record)
  end

  def include_record?(appeal)
    appeal.decisions.empty?
  end

  def cleanup_record(appeal)
    appeal.clear_documents!
  end
end
