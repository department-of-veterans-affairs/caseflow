class Generators::Vacols::CaseIssue

    class << self

        def case_issue_attrs
            {
              
            }
        end


        def create(attrs = {})
            case_issue_attrs.merge(attrs)

            VACOLS::CaseIssue.create(case_issue_attrs)
        end


    end

end