FactoryBot.define do
  factory :correspondent, class: VACOLS::Correspondent do
    sequence(:stafkey)

    transient do
      appellant_first_name nil
      appellant_middle_initial nil
      appellant_last_name nil
      appellant_relationship nil
    end

    sspare1 { appellant_first_name }
    sspare2 { appellant_middle_initial }
    sspare3 { appellant_last_name }
    susrtyp { appellant_relationship }
  end
end
