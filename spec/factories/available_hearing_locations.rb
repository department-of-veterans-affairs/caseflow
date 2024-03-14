# frozen_string_literal: true

FactoryBot.define do
  factory :available_hearing_locations do
    association :appeal
    distance { 0.0 }
    updated_at { Time.now.utc }
    veteran_file_number { appeal&.veteran_file_number || "" }

    trait "RO17" do
      address { "9500 Bay Pines Blvd." }
      city { "St. Petersburg" }
      classification { "Regional Benefit Office" }
      facility_id { "vba_317" }
      facility_type { "va_benefits_facility" }
      name { "St. Petersburg Regional Benefit Office" }
      state { "FL" }
      zip_code { "33744" }
    end

    trait "RO19" do
      address { "6437 Garners Ferry Rd" }
      city { "Columbia" }
      classification { "Regional Benefit Office" }
      facility_id { "vba_319" }
      facility_type { "va_benefits_facility" }
      name { "Columbia Regional Benefit Office" }
      state { "SC" }
      zip_code { "29209" }
    end

    trait "RO31" do
      address { "9700 Page Ave." }
      city { "ST. Louis" }
      classification { "Regional Benefit Office" }
      facility_id { "vba_331" }
      facility_type { "va_benefits_facility" }
      name { "St. Louis Regional Benefit Office" }
      state { "MO" }
      zip_code { "63132" }
    end

    trait "RO43" do
      address { "1301 Clay Street North Tower, Rm. 1400" }
      city { "Oakland" }
      classification { "Regional Benefit Office" }
      facility_id { "vba_343" }
      facility_type { "va_benefits_facility" }
      name { "Oakland Regional Benefit Office" }
      state { "CA" }
      zip_code { "94612" }
    end

    trait "RO45" do
      address { "3333 North Central Avenue" }
      city { "Phoenix" }
      classification { "Regional Benefit Office" }
      facility_id { "vba_345" }
      facility_type { "va_benefits_facility" }
      name { "Phoenix Regional Benefit Office" }
      state { "AZ" }
      zip_code { "85012" }
    end
  end
end
