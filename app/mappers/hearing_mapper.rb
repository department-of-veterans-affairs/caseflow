module HearingMapper
  def self.bfha_vacols_code(hearing_record, case_record)
    case hearing_record.hearing_disp
    when "H"
      return "1" if case_record.bfhr == "1"
      return "2" if case_record.bfhr == "2" && case_record.bfdocind != "V"
      return "6" if case_record.bfhr == "2" && case_record.bfdocind == "V"
    when "P"
      nil
    when "C"
      "5"
    else
      "5"
    end
  end
end
