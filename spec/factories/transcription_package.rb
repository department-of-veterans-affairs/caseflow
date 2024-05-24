# frozen_string_literal: true

FactoryBot.define do
  factory :transcription_package do
    aws_link_zip { "aws_link/zip_file" }
    aws_link_work_order { "aws_link/work_order" }
    created_by_id { create(:user).id }
    returned_at { DateTime.now }
    task_number { "#BVA-1111-0001" }
    date_upload_box { DateTime.now }
    date_upload_aws { DateTime.now }
  end
end
