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

    trait :disable_legacy_non_priority do
      item { "disable_legacy_non_priority" }
      title { "ACD Disable Legacy Non-priority" }
      description { "" }
      data_type { "boolean" }
      value { false }
      unit { "" }
      algorithms_used { %w[docket proportion] }
      lever_group { "docket_levers" }
      lever_group_order { 101 }
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
      item { "cavc_aod_affinity_days" }
      title { "CAVC AOD Affinity Days" }
      description do
        "Sets the number of days a case returned from CAVC respects the affinity to the judge who authored a decision "\
        "before distributing the appeal to any available judge. This does not include Legacy CAVC Remand Appeals with "\
        "a hearing held."
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
         { item: "infinite", value: "infinite", text: "Always distribute to current judge" },
         { item: "omit", value: "omit", text: "Omit variable from distribution rules" }]
      end
      algorithms_used { %w[docket proportion] }
      lever_group { "affinity" }
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

    trait :ama_evidence_submission_docket_time_goals do
      item { "ama_evidence_submission_docket_time_goals" }
      title { "AMA Evidence Submission Docket Time Goals" }
      data_type { "number" }
      value { 550 }
      unit { "days" }
      algorithms_used { ["docket"] }
      lever_group { "docket_time_goal" }
      lever_group_order { 4004 }
    end

    trait :ama_hearing_docket_time_goals do
      item { "ama_hearing_docket_time_goals" }
      title { "AMA Hearing Submission Docket Time Goals" }
      data_type { "number" }
      value { 730 }
      unit { "days" }
      algorithms_used { ["docket"] }
      lever_group { "docket_time_goal" }
      lever_group_order { 4004 }
    end

    trait :ama_hearing_start_distribution_prior_to_goals do
      item { "ama_hearing_start_distribution_prior_to_goals" }
      title { "AMA Hearings Start Distribution Prior to Goals" }
      data_type { "combination" }
      options do
        [
          {
            item: "value",
            data_type: "boolean",
            value: true,
            text: "This feature is turned on or off",
            unit: ""
          }
        ]
      end
      value { 60 }
      unit { "days" }
      is_toggle_active { true }
      algorithms_used { ["docket"] }
      lever_group { "docket_distribution_prior" }
      lever_group_order { 4000 }
    end

    trait :ama_direct_review_start_distribution_prior_to_goals do
      item { "ama_direct_review_start_distribution_prior_to_goals" }
      title { "AMA Direct Review Start Distribution Prior to Goals" }
      data_type { "combination" }
      options do
        [
          {
            item: "value",
            data_type: "boolean",
            value: true,
            text: "This feature is turned on or off",
            unit: ""
          }
        ]
      end
      value { 365 }
      unit { "days" }
      is_toggle_active { true }
      algorithms_used { ["docket"] }
      lever_group { "docket_distribution_prior" }
      lever_group_order { 4000 }
    end

    trait :ama_evidence_submission_review_start_distribution_prior_to_goals do
      item { "ama_evidence_submission_start_distribution_prior_to_goals" }
      title { "AMA Evidence Submission Start Distribution Prior to Goals" }
      data_type { "combination" }
      options do
        [
          {
            item: "value",
            data_type: "boolean",
            value: true,
            text: "This feature is turned on or off",
            unit: ""
          }
        ]
      end
      value { 365 }
      unit { "days" }
      is_toggle_active { true }
      algorithms_used { ["docket"] }
      lever_group { "docket_distribution_prior" }
      lever_group_order { 4000 }
    end

    trait :disable_ama_non_priority_direct_review do
      item { "disable_ama_non_priority_direct_review" }
      title { "ACD Disable AMA Non-Priority Direct Review" }
      data_type { "boolean" }
      options do
        [
          {
            displayText: "On",
            name: Constants.DISTRIBUTION.disable_ama_non_priority_direct_review,
            value: "true",
            disabled: false
          },
          {
            displayText: "Off",
            name: Constants.DISTRIBUTION.disable_ama_non_priority_direct_review,
            value: "false",
            disabled: false
          }
        ]
      end
      value { false }
      unit { "days" }
      algorithms_used { %w(proportion docket) }
      lever_group { "docket_levers" }
      lever_group_order { 103 }
      control_group { "non_priority" }
    end

    trait :disable_legacy_priority do
      item { "disable_legacy_priority" }
      title { "ACD Disable Legacy Priority" }
      data_type { "boolean" }
      options do
        [
          {
            displayText: "On",
            name: Constants.DISTRIBUTION.disable_legacy_priority,
            value: "true",
            disabled: false
          },
          {
            displayText: "Off",
            name: Constants.DISTRIBUTION.disable_legacy_priority,
            value: "false",
            disabled: false
          }
        ]
      end
      value { false }
      unit { "days" }
      algorithms_used { %w(proportion docket) }
      lever_group { "docket_levers" }
      lever_group_order { 103 }
      control_group { "priority" }
    end

    trait :disable_ama_priority_hearing do
      item { "disable_ama_priority_hearing" }
      title { "ACD Disable AMA Priority Hearing" }
      data_type { "boolean" }
      options do
        [
          {
            displayText: "On",
            name: Constants.DISTRIBUTION.disable_ama_priority_hearing,
            value: "true",
            disabled: false
          },
          {
            displayText: "Off",
            name: Constants.DISTRIBUTION.disable_ama_priority_hearing,
            value: "false",
            disabled: false
          }
        ]
      end
      value { false }
      unit { "days" }
      algorithms_used { %w(proportion docket) }
      lever_group { "docket_levers" }
      lever_group_order { 103 }
      control_group { "priority" }
    end

    trait :disable_ama_priority_direct_review do
      item { "disable_ama_priority_direct_review" }
      title { "ACD Disable AMA Priority Direct Review" }
      data_type { "boolean" }
      options do
        [
          {
            displayText: "On",
            name: Constants.DISTRIBUTION.disable_ama_priority_direct_review,
            value: "true",
            disabled: false
          },
          {
            displayText: "Off",
            name: Constants.DISTRIBUTION.disable_ama_priority_direct_review,
            value: "false",
            disabled: false
          }
        ]
      end
      value { false }
      unit { "days" }
      algorithms_used { %w(proportion docket) }
      lever_group { "docket_levers" }
      lever_group_order { 103 }
      control_group { "priority" }
    end

    trait :disable_ama_priority_evidence_submission do
      item { "disable_ama_priority_direct_review" }
      title { "ACD Disable AMA Priority Evidence Submission" }
      data_type { "boolean" }
      options do
        [
          {
            displayText: "On",
            name: Constants.DISTRIBUTION.disable_ama_priority_evidence_submission,
            value: "true",
            disabled: false
          },
          {
            displayText: "Off",
            name: Constants.DISTRIBUTION.disable_ama_priority_evidence_submission,
            value: "false",
            disabled: false
          }
        ]
      end
      value { false }
      unit { "days" }
      algorithms_used { %w(proportion docket) }
      lever_group { "docket_levers" }
      lever_group_order { 103 }
      control_group { "priority" }
    end

    trait :nonsscavlj_number_of_appeals_to_move do
      item { "nonsscavlj_number_of_appeals_to_move" }
      title { "Non-SSC/AVLJ Number of Appeals to Move" }
      data_type { "number" }
      value { 2 }
      unit { "" }
      algorithms_used { [] }
      lever_group { "internal" }
      lever_group_order { 999 }
    end
  end
end
