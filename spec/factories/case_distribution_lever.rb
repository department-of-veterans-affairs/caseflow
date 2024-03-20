# frozen_string_literal: true

FactoryBot.define do
  factory :case_distribution_lever do
    is_toggle_active { true }
    is_disabled_in_ui { false }
    min_value { 0 }

    trait :ama_direct_review_docket_time_goals do
      item { "ama_direct_review_docket_time_goals" }
      title { "AMA Direct Review Docket Time Goals" }
      data_type { "number" }
      value { 365 }
      unit { "days" }
      algorithms_used { ["docket"] }
      lever_group { "docket_time_goal" }
      lever_group_order { 4004 }
    end

    trait :bust_backlog do
      item { "bust_backlog" }
      title { "Priority Bust Backlog" }
      description { "Distribute legacy cases tied to a judge to the Board-provided limit of 30, regardless of the legacy docket range." } # rubocop:disable Layout/LineLength
      data_type { "boolean" }
      value { true }
      unit { "" }
      algorithms_used { ["proportion"] }
      lever_group { "static" }
      lever_group_order { 1003 }
    end

    trait :minimum_legacy_proportion do
      item { "minimum_legacy_proportion" }
      title { "Minimum Legacy Proportion" }
      description { "Sets the minimum proportion of legacy appeals that will be distributed." }
      data_type { "number" }
      value { 0.9 }
      unit { "%" }
      algorithms_used { ["proportion"] }
      lever_group { "static" }
      lever_group_order { 1001 }
    end

    trait :ama_hearings_start_distribution_prior_to_goals do
      item { "ama_hearings_start_distribution_prior_to_goals" }
      title { "AMA Hearings Start Distribution Prior to Goals" }
      data_type { "combination" }
      value { 60 }
      unit { "days" }
      options { [{ item: "value", data_type: "boolean", value: true, text: "This feature is turned on or off", unit: "" }] } # rubocop:disable Layout/LineLength
      algorithms_used { ["docket"] }
      lever_group { "docket_distribution_prior" }
      lever_group_order { 4000 }
    end

    trait :batch_size_per_attorney do
      item { "batch_size_per_attorney" }
      title { "Batch Size Per Attorney" }
      description { "Sets case-distribution batch size for judges with attorney teams. The value for this data element is per attorney." } # rubocop:disable Layout/LineLength
      data_type { "number" }
      value { 3 }
      unit { "cases" }
      algorithms_used { %w[docket proportion] }
      lever_group { "batch" }
      lever_group_order { 2001 }
    end

    trait :request_more_cases_minimum do
      item { "request_more_cases_minimum" }
      title { "Request More Cases Minimum" }
      description { "Sets the number of remaining cases a VLJ must have equal to or less than to request more cases. (The number entered is used as equal to or less than)" } # rubocop:disable Layout/LineLength
      data_type { "number" }
      value { 8 }
      unit { "cases" }
      algorithms_used { %w[docket proportion] }
      lever_group { "batch" }
      lever_group_order { 2002 }
    end

    trait :ama_hearing_case_affinity_days do
      item { "ama_hearing_case_affinity_days" }
      title { "AMA Hearing Case Affinity Days" }
      description { "For non-priority AMA Hearing cases, sets the number of days an AMA Hearing Case is tied to the judge that held the hearing." } # rubocop:disable Layout/LineLength
      data_type { "radio" }
      value { "60" }
      unit { "days" }
      options do
        [{ item: "value",
           data_type: "number",
           value: 60,
           text: "Attempt distribution to current judge for max of:",
           unit: "days",
           min_value: 0,
           max_value: 999,
           selected: true },
         { item: "infinite", value: "infinite", text: "Always distribute to current judge" },
         { item: "omit", value: "omit", text: "Omit variable from distribution rules" }]
      end
      algorithms_used { ["docket"] }
      lever_group { "affinity" }
      lever_group_order { 3000 }
    end
  end
end
