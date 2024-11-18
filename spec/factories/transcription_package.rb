# frozen_string_literal: true

FactoryBot.define do
  factory :transcription_package do
    aws_link_zip { "vaec-appeals-caseflow-test/transcript_text/BVAaa-1111-0001.zip" }
    aws_link_work_order { "vaec-appeals-caseflow-test/transcript_text/BVA-1111-0001.xls" }
    created_by_id { create(:user).id }
    returned_at { Time.utc(2050, 12, 1) }
    task_number { "BVA-1111-0001" }
    expected_return_date { Time.zone.now + 14.days }
    date_upload_box { Time.utc(2050, 12, 2) }
    date_upload_aws { Time.utc(2050, 12, 3) }
    status { "Successful Retrieval (BOX)" }
    contractor { create(:transcription_contractor) }
  end
end
