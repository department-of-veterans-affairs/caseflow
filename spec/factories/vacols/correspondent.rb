FactoryBot.define do
  factory :correspondent, class: VACOLS::Correspondent do
    sequence(:stafkey)

    snamef "Joshua"
    snamel "Chamberlain"
    ssalut "PhD"

    transient do
      appellant_first_name nil
      appellant_middle_initial nil
      appellant_last_name nil
      appellant_relationship nil
    end

    sspare1 { appellant_last_name }
    sspare2 { appellant_first_name }
    sspare3 { appellant_middle_initial }
    susrtyp { appellant_relationship }
  end
end
