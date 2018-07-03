FactoryBot.define do
  factory :certification do
    transient do
      vacols_case nil
    end

    vacols_id { vacols_case.bfkey }
  end

  trait :default_representative do
    vacols_representative_name "VACOLS_NAME"
    bgs_representative_name "BGS_NAME"
    vacols_representative_type "VACOLS_TYPE"
    bgs_representative_type "BGS_TYPE"
    representative_name "NAME"
    representative_type "TYPE"
  end

  trait :poa_matches do
    poa_matches true
  end

  trait :poa_correct_in_bgs do
    poa_correct_in_bgs true
  end

  trait :poa_correct_in_vacols do
    poa_correct_in_vacols true
  end
end
