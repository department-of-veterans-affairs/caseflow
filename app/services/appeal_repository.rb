class AppealRepository
  def self.find(vacols_id, _args = {})
    case_record = Records::Case.includes(:folder, :correspondent).find(vacols_id)

    Appeal.from_records(
      case_record: case_record,
      folder_record: case_record.folder,
      correspondent_record: case_record.correspondent
    )
  end

  def self.cerify(_appeal)
    # Set certification flags on VACOLS record
    # upload Form 8 to VBMS

    #  @kase.bfdcertool = Time.now
    #  @kase.bf41stat = Date.strptime(params[:certification_date], Date::DATE_FORMATS[:va_date])
    #  @kase.save
    #  @kase.efolder_case.upload_form8(corr.snamef, corr.snamemi, corr.snamel, params[:file_name])
  end
end
