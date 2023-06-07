# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_ext_claim do
    sequence(:claim_id) { |n| "10000#{n}" }
    sync_id { 1 }
    createddt { Time.zone.now }
    lastupdatedt { Time.zone.now }
    expirationdt { Time.zone.now }
    version { 22 }
    prevent_audit_trig { 2 }

    trait :linked_epe do
    end

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
