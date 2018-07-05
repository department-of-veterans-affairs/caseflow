FactoryBot.define do
  factory :folder, class: VACOLS::Folder do
    sequence(:ticknum)
    sequence(:tinum)
  end
end
