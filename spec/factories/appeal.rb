FactoryBot.define do
  factory :appeal do
    transient do
      veteran nil
    end

    veteran_file_number do
      if veteran
        veteran.file_number
      end
    end

    association task
  end
end
