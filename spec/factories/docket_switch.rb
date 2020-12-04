# frozen_string_literal: true

FactoryBot.define do
  factory :docket_switch do
    old_docket_stream { create(:appeal, docket_type: Constants.AMA_DOCKETS.evidence_submission) }
    new_docket_stream { create(:appeal, stream_type: Constants.AMA_STREAM_TYPES.original) }
    task { create(:docket_switch_mail_task) }
    receipt_date { 5.days.ago }
    docket_type { Constants.AMA_DOCKETS.hearing }
    disposition { "granted" }
  end
end
