# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_ext_claim do
    # prevents vbms_ext_claim from having a duplicate key
    sequence(:claim_id) do
      if VbmsExtClaim.any?
        (VbmsExtClaim.last.claim_id + 1).to_s
      else
        "300000"
      end
    end
    claim_date { Time.zone.now - 1.day }
    sync_id { 1 }
    createddt { Time.zone.now - 1.day }
    establishment_date { Time.zone.now - 1.day }
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

    # high_level_review ext claim
    trait :hlr do
      EP_CODE { "030" }
      TYPE_CODE { "030HLRR" }
      PAYEE_CODE { "00" }
    end
    # supplemental_claim ext claim
    trait :slc do
      EP_CODE { "040" }
      TYPE_CODE { "040SCR" }
      PAYEE_CODE { "00" }
    end
  end
end
