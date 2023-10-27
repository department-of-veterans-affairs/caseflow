# frozen_string_literal: true

class Api::V3::VbmsIntake::Legacy::VbmsLegacyAppealSerializer
  include JSONAPI::Serializer
  set_type :appeal

  attributes :id, :nod_date, :status, :soc_date, :ssoc_dates
end

    # "id" : "LEGACYID",
    # "notice_of_disagreement_date" : "Mon, 22 Aug 2022 00:00:00 UTC +00:00", = las.first.appeal.nod_date
    # "legacy_appeal_status" : "Advance", = las.first.appeal.status
    # "legacy_appeal_soc_date" : "Wed, 22 Feb 2023 000000 UTC +0000", = las.first.appeal.soc_date
    # "legacy_appeal_ssoc_dates" : [], = las.first.appeal.ssoc_dates
    # "legacy_appeal_eligible_for_opt_in" : "false",  = las.first.appeal.eligible_for_opt_in?(receipt_date: Time.zone.today)
    # "legacy_appeal_eligible_for_soc_opt_in_with_exemption" : "true", = las.first.appeal.eligible_for_opt_in?(receipt_date: Time.zone.today, covid_flag: true )

