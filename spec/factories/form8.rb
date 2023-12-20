# frozen_string_literal: true

FactoryBot.define do
  factory :form8 do
    factory :default_form8 do
      appellant_name { "Brad Pitt" }
      appellant_relationship { "Fancy man" }
      veteran_name { "Joe Patriot" }
    end
  end
end
