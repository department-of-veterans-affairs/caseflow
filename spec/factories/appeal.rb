FactoryBot.define do
  factory :appeal do
    transient do
      veteran_object "Test"
    end

    veteran_file_number do
      if veteran_object
        veteran_object.file_number
      else
        "783740847"
      end
    end
  end
end
