# frozen_string_literal: true

FactoryBot.define do
  factory :transcription_package do
    aws_link_zip { "vaec-appeals-caseflow-test/transcript_text/BVAaa-1111-0001.zip" }
    aws_link_work_order { "vaec-appeals-caseflow-test/transcript_text/BVA-1111-0001.xls" }
    created_by_id { create(:user).id }
    returned_at { Time.new(2050, 01, 01) }
    task_number { "BVA-1111-0001" }
    date_upload_box { Time.new(2050, 01, 01) }
    date_upload_aws { Time.new(2050, 01, 01) }
  end
end
