FactoryBot.define do
  factory :appeal do
    transient do
      veteran_object nil
    end

    # veteran_file_number { "TEST" }
    # do
    #    "783740847"
    #   # if veteran_object
    #   #   veteran_object.file_number
    #   # else
    #   #   "783740847"
    #   # end
    # end
  end
end
