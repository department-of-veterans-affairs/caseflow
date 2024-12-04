# frozen_string_literal: true

FactoryBot.define do
  factory :transcription_file do
    hearing { create(:hearing, :held) }
    docket_number { hearing.docket_number }
    hearing_id { hearing.id }
    hearing_type { hearing.request_type }
    file_name { "transcript.vtt" }
    file_type { "vtt" }
  end

  trait :uploaded do
    aws_link { "aws-link/#{hearing.docket_number}_#{hearing.id}_Hearing.vtt" }
  end
end
