module RemandReasonMapper
  class << self
    def rename_and_validate_vacols_attrs(slogid, remand_reasons)
      remand_reasons.map do |remand_reason|
        {
          rmdval:  remand_reason[:code],
          rmddev: remand_reason[:after_certification] ? "R2" : "R1",
          rmdmdusr: slogid,
          rmdmdtim: VacolsHelper.local_time_with_utc_timezone
        }
      end
    end
  end
end
