FactoryBot.define do
  factory :appeal do
    transient do
      veteran nil
    end

    veteran_file_number do
      if veteran
        veteran.file_number
      else
        "783740847"
      end
    end

    uuid do
      "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
    end
  end
end
