# frozen_string_literal: true

FactoryBot.define do
  factory :transcription_file do
    hearing { create(:hearing, :held) }
    docket_number { hearing.docket_number }
    file_name { "transcript.vtt" }
    file_type { "vtt" }
    transcription_id { nil }
    association :transcription, factory: :transcription
    date_returned_box { nil }
  end

  trait :uploaded do
    aws_link { "aws-link/#{hearing.docket_number}_#{hearing.id}_Hearing.vtt" }
  end
end
