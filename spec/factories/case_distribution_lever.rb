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
      description do
        "Distribute legacy cases tied to a judge to the Board-provided limit of 30, regardless of the legacy docket "\
        "range."
      end
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

    trait :maximum_direct_review_proportion do
      item { "maximum_direct_review_proportion" }
      title { "Maximum Direct Review Proportion" }
      description do
        "Sets the maximum number of direct reviews in relation to due direct review proportion to prevent a complete "\
        "halt to work on other dockets should demand for direct reviews approach the Board's capacity."
      end
      data_type { "number" }
      value { 0.07 }
      unit { "%" }
      algorithms_used { ["proportion"] }
      lever_group { "static" }
      lever_group_order { 1000 }
    end

    trait :nod_adjustment do
      item { "nod_adjustment" }
      title { "NOD Adjustment" }
      description { "Applied for docket balancing reflecting the likelihood that NODs will advance to a Form 9." }
      data_type { "number" }
      value { 0.4 }
      unit { "%" }
      algorithms_used { ["proportion"] }
      lever_group { "static" }
      lever_group_order { 1002 }
    end

    trait :ama_hearings_start_distribution_prior_to_goals do
      item { "ama_hearings_start_distribution_prior_to_goals" }
      title { "AMA Hearings Start Distribution Prior to Goals" }
      data_type { "combination" }
      value { 60 }
      unit { "days" }
      options do
        [
          { item: "value", data_type: "boolean", value: true,
            text: "This feature is turned on or off", unit: "" }
        ]
      end
      algorithms_used { ["docket"] }
      lever_group { "docket_distribution_prior" }
      lever_group_order { 4000 }
    end

    trait :ama_direct_review_start_distribution_prior_to_goals do
      item { "ama_direct_review_start_distribution_prior_to_goals" }
      title { "AMA Direct Review Start Distribution Prior to Goals" }
      data_type { "combination" }
      value { 365 }
      unit { "days" }
      options do
        [
          { item: "value", data_type: "boolean", value: true, text: "This feature is turned on or off", unit: "" }
        ]
      end
      algorithms_used { ["docket"] }
      lever_group { "docket_distribution_prior" }
      lever_group_order { 4001 }
    end

    trait :batch_size_per_attorney do
      item { "batch_size_per_attorney" }
      title { "Batch Size Per Attorney" }
      description do
        "Sets case-distribution batch size for judges with attorney teams. The value for this data "\
        "element is per attorney."
      end
      data_type { "number" }
      value { 3 }
      unit { "cases" }
      algorithms_used { %w[docket proportion] }
      lever_group { "batch" }
      lever_group_order { 2001 }
    end

    trait :alternative_batch_size do
      item { "alternative_batch_size" }
      title { "Alternate Batch Size" }
      description { "Sets case-distribution batch size for judges who do not have their own attorney teams.." }
      data_type { "number" }
      value { 15 }
      unit { "cases" }
      algorithms_used { %w[docket proportion] }
      lever_group { "batch" }
      lever_group_order { 2000 }
    end

    trait :request_more_cases_minimum do
      item { "request_more_cases_minimum" }
      title { "Request More Cases Minimum" }
      description do
        "Sets the number of remaining cases a VLJ must have equal to or less than to request more cases. "\
        "(The number entered is used as equal to or less than)"
      end
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

    trait :cavc_affinity_days do
      item { "cavc_affinity_days" }
      title { "CAVC Affinity Days" }
      description do
        "Sets the number of days a case returned from CAVC respects the affinity to the judge who authored a decision "\
        "before distributing the appeal to any available judge. This does not include Legacy CAVC Remand Appeals with "\
        "a hearing held."
      end
      data_type { "radio" }
      value { "21" }
      unit { "days" }
      options do
        [{ item: "value",
           data_type: "number",
           value: 21,
           text: "Attempt distribution to current judge for max of:",
           unit: "days",
           selected: true },
         { item: "infinite", value: "infinite", text: "Always distribute to current judge" },
         { item: "omit", value: "omit", text: "Omit variable from distribution rules" }]
      end
      algorithms_used { %w[docket proportion] }
      lever_group { "affinity" }
      lever_group_order { 3002 }
    end

    trait :cavc_aod_affinity_days do
      item { Constants.DISTRIBUTION.cavc_aod_affinity_days }
      title { Constants.DISTRIBUTION.cavc_aod_affinity_days_title }
      description do
        "Sets the number of days appeals returned from CAVC that are also AOD respect the affinity to the deciding "\
        "judge. This is not applicable for legacy apeals for which the deciding judge conducted the most recent"\
        "hearing."
      end
      data_type { Constants.ACD_LEVERS.data_types.radio }
      value { "14" }
      unit { "days" }
      options do
        [{ item: Constants.ACD_LEVERS.value,
           data_type: Constants.ACD_LEVERS.data_types.number,
           value: 14,
           text: "Attempt distribution to current judge for max of:",
           unit: Constants.ACD_LEVERS.days,
           selected: true },
         { item: Constants.ACD_LEVERS.infinite,
           value: Constants.ACD_LEVERS.infinite,
           text: "Always distribute to current judge" },
         { item: Constants.ACD_LEVERS.omit,
           value: Constants.ACD_LEVERS.omit,
           text: "Omit variable from distribution rules" }]
      end
      algorithms_used { [Constants.ACD_LEVERS.algorithms.proportion] }
      lever_group { Constants.ACD_LEVERS.lever_groups.affinity }
      lever_group_order { 3003 }
    end

    trait :ama_hearing_case_aod_affinity_days do
      item { "ama_hearing_case_aod_affinity_days" }
      title { "AMA Hearing Case AOD Affinity Days" }
      description do
        "Sets the number of days an AMA Hearing appeal that is also AOD will respect the affinity to the "\
        "most-recent hearing judge before distributing the appeal to any available judge."
      end
      data_type { "radio" }
      value { "14" }
      unit { "days" }
      options do
        [{ item: "value",
           data_type: "number",
           value: 14,
           text: "Attempt distribution to current judge for max of:",
           unit: "days",
           selected: true },
         { item: "infinite", data_type: "", value: "infinite", text: "Always distribute to current judge", unit: "" },
         { item: "omit", data_type: "", value: "omit", text: "Omit variable from distribution rules", unit: "" }]
      end
      algorithms_used { ["docket"] }
      lever_group { "affinity" }
      lever_group_order { 3000 }
    end
  end
end
