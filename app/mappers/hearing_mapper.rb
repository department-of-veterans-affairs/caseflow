module HearingMapper
  class << self
    def bfha_vacols_code(hearing_record, case_record)
      case hearing_record.hearing_disp
      when "H"
        code_based_on_hearing_type(case_record)
      when "P"
        nil
      when "C"
        "5"
      when "N"
        "5"
      end
    end

    private

    def code_based_on_hearing_type(case_record)
      return "1" if case_record.bfhr == "1"
      return "2" if case_record.bfhr == "2" && case_record.bfdocind != "V"
      return "6" if case_record.bfhr == "2" && case_record.bfdocind == "V"
    end
  end
end
