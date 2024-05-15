# frozen_string_literal: true

FactoryBot.define do
  factory :correspondent, class: VACOLS::Correspondent do
    stafkey { generate :vacols_correspondent_key }

    snamef { "Joshua" }
    snamel { "Chamberlain" }
    ssalut { "PhD" }

    after(:create) do |correspondent, _evaluator|
      # Create a corresponding Veteran record in the Caseflow DB; this will also create a corresponding Redis record to
      # make these cases searchable. Simply creating the redis record here will cause downstream issues when searching.
      unless Veteran.exists?(file_number: correspondent.ssn)

      create(
        :veteran,
        first_name: correspondent.snamef,
        last_name: correspondent.snamel,
        name_suffix: correspondent.ssalut,
        ssn: correspondent.ssn,
        file_number: correspondent.ssn
      )
    end

    transient do
      appellant_first_name { nil }
      appellant_middle_initial { nil }
      appellant_last_name { nil }
      appellant_relationship { nil }
    end

    sspare1 { appellant_last_name }
    sspare2 { appellant_first_name }
    sspare3 { appellant_middle_initial }
    susrtyp { appellant_relationship }
  end
end
