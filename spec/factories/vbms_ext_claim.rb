# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_ext_claim do
    # prevents vbms_ext_claim to have a duplicate key
    sequence(:claim_id) do |n|
      if VbmsExtClaim.last
        (VbmsExtClaim.last.claim_id + n).to_s
      else
        (100_00 + n).to_s
      end
    end

    sync_id { 1 }
    createddt { Time.zone.now - 1.day }
    lastupdatedt { Time.zone.now }
    expirationdt { Time.zone.now + 5.days }
    version { 22 }
    prevent_audit_trig { 2 }

    trait :cleared do
      LEVEL_STATUS_CODE { "CLR" }
    end

    trait :canceled do
      LEVEL_STATUS_CODE { "CAN" }
    end

    # rdc: rating decision complete
    trait :rdc do
      LEVEL_STATUS_CODE { "RDC" }
    end
  end
end
