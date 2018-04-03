class Generators::Vacols::CaseHearing

    class << self

        def case_hearing_attrs
            {
              
            }
        end


        def create(attrs = {})
            case_hearing_attrs.merge(attrs)

            VACOLS::CaseHearing.create(case_hearing_attrs)
        end


    end

end