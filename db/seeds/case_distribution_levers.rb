module Seeds
  class CaseDistributionLevers < Base
    # Creates new levers and updates existing levers
    # For existing levers it does not update every field, there is a separate but DANGEROUS operation for that
    def seed!
      updated_levers = []

      CaseDistributionLevers.levers.each do |lever|
        existing_lever = CaseDistributionLever.find_by_item(lever[:item])
        if existing_lever.present?
          updated_levers << update_lever(lever, existing_lever)
        else
          create_lever(lever)
        end
      end

      validate_levers_creation
      updated_levers.compact!
      puts "#{updated_levers.count} levers updated: #{updated_levers}" if updated_levers.count > 0
    end

    def self.levers
      [
        {
          item: Constants.DISTRIBUTION.maximum_direct_review_proportion,
          title: Constants.DISTRIBUTION.maximum_direct_review_proportion_title,
          description: "Sets the maximum number of direct reviews in relation to due direct review proportion to prevent a complete halt to work on other dockets should demand for direct reviews approach the Board's capacity.",
          data_type: Constants.ACD_LEVERS.data_types.number,
          value: 0.07,
          unit: '%',
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion],
          lever_group: Constants.ACD_LEVERS.lever_groups.static,
          lever_group_order: 1000
        },
        {
          item: Constants.DISTRIBUTION.minimum_legacy_proportion,
          title: Constants.DISTRIBUTION.minimum_legacy_proportion_title,
          description: 'Sets the minimum proportion of legacy appeals that will be distributed.',
          data_type: Constants.ACD_LEVERS.data_types.number,
          value: 0.9,
          unit: '%',
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion],
          lever_group: Constants.ACD_LEVERS.lever_groups.static,
          lever_group_order: 1001
        },
        {
          item: Constants.DISTRIBUTION.nod_adjustment,
          title: Constants.DISTRIBUTION.nod_adjustment_title,
          description: 'Applied for docket balancing reflecting the likelihood that NODs will advance to a Form 9.',
          data_type: Constants.ACD_LEVERS.data_types.number,
          value: 0.4,
          unit: '%',
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion],
          lever_group: Constants.ACD_LEVERS.lever_groups.static,
          lever_group_order: 1002
        },
        {
          item: Constants.DISTRIBUTION.bust_backlog,
          title: Constants.DISTRIBUTION.bust_backlog_title,
          description: 'Distribute legacy cases tied to a judge to the Board-provided limit of 30, regardless of the legacy docket range.',
          data_type: Constants.ACD_LEVERS.data_types.boolean,
          value: true,
          unit: '',
          is_disabled_in_ui: true,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion],
          lever_group: Constants.ACD_LEVERS.lever_groups.static,
          lever_group_order: 1003
        },
        {
          item: Constants.DISTRIBUTION.alternative_batch_size,
          title: Constants.DISTRIBUTION.alternative_batch_size_title,
          description: 'Sets case-distribution batch size for judges who do not have their own attorney teams.',
          data_type: Constants.ACD_LEVERS.data_types.number,
          value: 15,
          unit: Constants.ACD_LEVERS.cases,
          is_disabled_in_ui: false,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket, Constants.ACD_LEVERS.algorithms.proportion],
          lever_group: Constants.ACD_LEVERS.lever_groups.batch,
          lever_group_order: 2000
        },
        {
          item: Constants.DISTRIBUTION.batch_size_per_attorney,
          title: Constants.DISTRIBUTION.batch_size_per_attorney_title,
          description: 'Sets case-distribution batch size for judges with attorney teams. The value for this data element is per attorney.',
          data_type: Constants.ACD_LEVERS.data_types.number,
          value: 3,
          unit: Constants.ACD_LEVERS.cases,
          is_disabled_in_ui: false,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket, Constants.ACD_LEVERS.algorithms.proportion],
          lever_group: Constants.ACD_LEVERS.lever_groups.batch,
          lever_group_order: 2001
        },
        {
          item: Constants.DISTRIBUTION.request_more_cases_minimum,
          title: Constants.DISTRIBUTION.request_more_cases_minimum_title,
          description: 'Sets the number of remaining cases a VLJ must have equal to or less than to request more cases. (The number entered is used as equal to or less than)',
          data_type: Constants.ACD_LEVERS.data_types.number,
          value: 8,
          unit: Constants.ACD_LEVERS.cases,
          is_disabled_in_ui: false,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket, Constants.ACD_LEVERS.algorithms.proportion],
          lever_group: Constants.ACD_LEVERS.lever_groups.batch,
          lever_group_order: 2002
        },
        {
          item: Constants.DISTRIBUTION.ama_hearing_case_affinity_days,
          title: Constants.DISTRIBUTION.ama_hearing_case_affinity_days_title,
          description: 'For non-priority AMA Hearing cases, sets the number of days an AMA Hearing Case is tied to the judge that held the hearing.',
          data_type: Constants.ACD_LEVERS.data_types.radio,
          value: '0',
          unit: Constants.ACD_LEVERS.days,
          options: [
            {
              item: 'value',
              data_type: Constants.ACD_LEVERS.data_types.number,
              value: 60,
              text: 'Attempt distribution to current judge for max of:',
              unit: Constants.ACD_LEVERS.days,
              min_value: 0,
              max_value: 100,
              selected: true
            },
            {
              item: Constants.ACD_LEVERS.infinite,
              value: Constants.ACD_LEVERS.infinite,
              text: 'Always distribute to current judge',
            },
            {
              item: Constants.ACD_LEVERS.omit,
              value: Constants.ACD_LEVERS.omit,
              text: 'Omit variable from distribution rules',
            }
          ],
          is_disabled_in_ui: false,
          min_value: 0,
          max_value: 100,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.affinity,
          lever_group_order: 3000
        },
        {
          item: Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days,
          title: Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days_title,
          description: 'Sets the number of days an AMA Hearing appeal that is also AOD will respect the affinity to the most-recent hearing judge before distributing the appeal to any available judge.',
          data_type: Constants.ACD_LEVERS.data_types.radio,
          value: '0',
          unit: Constants.ACD_LEVERS.days,
          options: [
            {
              item: 'value',
              data_type: Constants.ACD_LEVERS.data_types.number,
              value: 14,
              text: 'Attempt distribution to current judge for max of:',
              unit: Constants.ACD_LEVERS.days,
              selected: true
            },
            {
              item: Constants.ACD_LEVERS.infinite,
              data_type: '',
              value: Constants.ACD_LEVERS.infinite,
              text: 'Always distribute to current judge',
              unit: ''
            },
            {
              item: Constants.ACD_LEVERS.omit,
              data_type: '',
              value: Constants.ACD_LEVERS.omit,
              text: 'Omit variable from distribution rules',
              unit: ''
            }
          ],
          is_disabled_in_ui: false,
          min_value: 0,
          max_value: 100,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.affinity,
          lever_group_order: 3001
        },
        {
          item: Constants.DISTRIBUTION.cavc_affinity_days,
          title: Constants.DISTRIBUTION.cavc_affinity_days_title,
          description: 'Sets the number of days a case returned from CAVC respects the affinity to the judge who authored a decision before distributing the appeal to any available judge. This does not include Legacy CAVC Remand Appeals with a hearing held.',
          data_type: Constants.ACD_LEVERS.data_types.radio,
          value: '0',
          unit: Constants.ACD_LEVERS.days,
          options: [
            {
              item: 'value',
              data_type: Constants.ACD_LEVERS.data_types.number,
              value: 21,
              text: 'Attempt distribution to current judge for max of:',
              unit: Constants.ACD_LEVERS.days,
              selected: true
            },
            {
              item: Constants.ACD_LEVERS.infinite,
              value: Constants.ACD_LEVERS.infinite,
              text: 'Always distribute to current judge'
            },
            {
              item: Constants.ACD_LEVERS.omit,
              value: Constants.ACD_LEVERS.omit,
              text: 'Omit variable from distribution rules'
            }
          ],
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket, Constants.ACD_LEVERS.algorithms.proportion],
          lever_group: Constants.ACD_LEVERS.lever_groups.affinity,
          lever_group_order: 3002
        },
        {
          item: Constants.DISTRIBUTION.cavc_aod_affinity_days,
          title: Constants.DISTRIBUTION.cavc_aod_affinity_days_title,
          description: 'Sets the number of days appeals returned from CAVC that are also AOD respect the affinity to the deciding judge. This is not applicable for legacy apeals for which the deciding judge conducted the most recent hearing.',
          data_type: Constants.ACD_LEVERS.data_types.radio,
          value: '21',
          unit: Constants.ACD_LEVERS.days,
          options: [
            {
              item: 'value',
              data_type: Constants.ACD_LEVERS.data_types.number,
              value: 14,
              text: 'Attempt distribution to current judge for max of:',
              unit: Constants.ACD_LEVERS.days,
              selected: true
            },
            {
              item: Constants.ACD_LEVERS.infinite,
              value: Constants.ACD_LEVERS.infinite,
              text: 'Always distribute to current judge',
            },
            {
              item: Constants.ACD_LEVERS.omit,
              value: Constants.ACD_LEVERS.omit,
              text: 'Omit variable from distribution rules',
            }
          ],
          is_disabled_in_ui: true,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion],
          lever_group: Constants.ACD_LEVERS.lever_groups.affinity,
          lever_group_order: 3003
        },
        {
          item: Constants.DISTRIBUTION.aoj_affinity_days,
          title: Constants.DISTRIBUTION.aoj_affinity_days_title,
          description: 'Sets the number of days an appeal respects the affinity to the deciding judge for Legacy AOJ Remand Returned appeals with no hearing held before distributing the appeal to any available judge.',
          data_type: Constants.ACD_LEVERS.data_types.radio,
          value: '0',
          unit: Constants.ACD_LEVERS.days,
          options: [
            {
              item: 'value',
              data_type: Constants.ACD_LEVERS.data_types.number,
              value: 60,
              text: 'Attempt distribution to current judge for max of:',
              unit: Constants.ACD_LEVERS.days,
              selected: true
            },
            {
              item: Constants.ACD_LEVERS.infinite,
              data_type: '',
              value: Constants.ACD_LEVERS.infinite,
              text: 'Always distribute to current judge',
              unit: ''
            },
            {
              item: Constants.ACD_LEVERS.omit,
              data_type: '',
              value: Constants.ACD_LEVERS.omit,
              text: 'Omit variable from distribution rules',
              unit: ''
            }
          ],
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.affinity,
          lever_group_order: 3004
        },
        {
          item: Constants.DISTRIBUTION.aoj_aod_affinity_days,
          title: Constants.DISTRIBUTION.aoj_aod_affinity_days_title,
          description: 'Sets the number of days legacy remand Returned appeals that are also AOD (and may or may not have been CAVC at one time) respect the affinity before distributing the appeal to any available jduge. Affects appeals with hearing held when the remanding judge is not the hearing judge, or any legacy AOD + AOD appeal with no hearing held (whether or not it had been CAVC at one time).',
          data_type: Constants.ACD_LEVERS.data_types.radio,
          value: '14',
          unit: Constants.ACD_LEVERS.days,
          options: [
            {
              item: 'value',
              data_type: Constants.ACD_LEVERS.data_types.number,
              value: 14,
              text: 'Attempt distribution to current judge for max of:',
              unit: Constants.ACD_LEVERS.days,
              selected: true
            },
            {
              item: Constants.ACD_LEVERS.infinite,
              data_type: '',
              value: Constants.ACD_LEVERS.infinite,
              text: 'Always distribute to current judge',
              unit: ''
            },
            {
              item: Constants.ACD_LEVERS.omit,
              data_type: '',
              value: Constants.ACD_LEVERS.omit,
              text: 'Omit variable from distribution rules',
              unit: ''
            }
          ],
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.affinity,
          lever_group_order: 3005
        },
        {
          item: Constants.DISTRIBUTION.aoj_cavc_affinity_days,
          title: Constants.DISTRIBUTION.aoj_cavc_affinity_days_title,
          description: 'Sets the number of days AOJ appeals that were CAVC at some time respect the affinity before the appeal is distributed to any available judge. This applies to any AOJ + CAVC appeal with no hearing held, or those with a hearing held when the remanding judge is not the hearing judge.',
          data_type: Constants.ACD_LEVERS.data_types.radio,
          value: '21',
          unit: Constants.ACD_LEVERS.days,
          options: [
            {
              item: 'value',
              data_type: Constants.ACD_LEVERS.data_types.number,
              value: 21,
              text: 'Attempt distribution to current judge for max of:',
              unit: Constants.ACD_LEVERS.days,
              selected: true
            },
            {
              item: Constants.ACD_LEVERS.infinite,
              data_type: '',
              value: Constants.ACD_LEVERS.infinite,
              text: 'Always distribute to current judge',
              unit: ''
            },
            {
              item: Constants.ACD_LEVERS.omit,
              data_type: '',
              value: Constants.ACD_LEVERS.omit,
              text: 'Omit variable from distribution rules',
              unit: ''
            }
          ],
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.affinity,
          lever_group_order: 3006
        },
        {
          item: Constants.DISTRIBUTION.ama_hearings_start_distribution_prior_to_goals,
          title: 'AMA Hearings Start Distribution Prior to Goals',
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.combination,
          value: 60,
          unit: Constants.ACD_LEVERS.days,
          options: [
            {
              item: 'value',
              data_type: Constants.ACD_LEVERS.data_types.boolean,
              value: true,
              text: 'This feature is turned on or off',
              unit: ''
            }
          ],
          is_toggle_active: false,
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_distribution_prior,
          lever_group_order: 4000
        },
        {
          item: Constants.DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals,
          title: 'AMA Direct Review Start Distribution Prior to Goals',
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.combination,
          value: 365,
          unit: Constants.ACD_LEVERS.days,
          options: [
            {
              item: 'value',
              data_type: Constants.ACD_LEVERS.data_types.boolean,
              value: true,
              text: 'This feature is turned on or off',
              unit: ''
            }
          ],
          is_toggle_active: false,
          is_disabled_in_ui: false,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_distribution_prior,
          lever_group_order: 4001
        },
        {
          item: Constants.DISTRIBUTION.ama_evidence_submission_start_distribution_prior_to_goals,
          title: 'AMA Evidence Submission Start Distribution Prior to Goals',
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.combination,
          value: 60,
          unit: Constants.ACD_LEVERS.days,
          options: [
            {
              item: 'value',
              data_type: Constants.ACD_LEVERS.data_types.boolean,
              value: true,
              text: 'This feature is turned on or off',
              unit: ''
            }
          ],
          is_toggle_active: false,
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_distribution_prior,
          lever_group_order: 4002
        },
        {
          item: Constants.DISTRIBUTION.ama_hearings_docket_time_goals,
          title: 'AMA Hearings Docket Time Goals',
          data_type: Constants.ACD_LEVERS.data_types.number,
          value: 730,
          unit: Constants.ACD_LEVERS.days,
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_time_goal,
          lever_group_order: 4003
        },
        {
          item: Constants.DISTRIBUTION.ama_direct_review_docket_time_goals,
          title: 'AMA Direct Review Docket Time Goals',
          data_type: Constants.ACD_LEVERS.data_types.number,
          value: 365,
          unit: Constants.ACD_LEVERS.days,
          is_disabled_in_ui: false,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_time_goal,
          lever_group_order: 4004
        },
        {
          item: Constants.DISTRIBUTION.ama_evidence_submission_docket_time_goals,
          title: 'AMA Evidence Submission Docket Time Goals',
          data_type: Constants.ACD_LEVERS.data_types.number,
          value: 550,
          unit: Constants.ACD_LEVERS.days,
          is_disabled_in_ui: true,
          min_value: 0,
          max_value: nil,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_time_goal,
          lever_group_order: 4005
        },
        {
          item: Constants.DISTRIBUTION.disable_legacy_priority,
          title: Constants.DISTRIBUTION.disable_legacy_priority_title,
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.boolean,
          value: false,
          unit: '',
          is_disabled_in_ui: true,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion, Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_levers,
          lever_group_order: 10
        },
        {
          item: Constants.DISTRIBUTION.disable_legacy_non_priority,
          title: Constants.DISTRIBUTION.disable_legacy_non_priority_title,
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.boolean,
          value: false,
          unit: '',
          is_disabled_in_ui: true,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion, Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_levers,
          lever_group_order: 101
        },
        {
          item: Constants.DISTRIBUTION.disable_ama_non_priority_hearing,
          title: Constants.DISTRIBUTION.disable_ama_non_priority_hearing_title,
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.boolean,
          value: false,
          unit: '',
          is_disabled_in_ui: true,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion, Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_levers,
          lever_group_order: 102
        },
        {
          item: Constants.DISTRIBUTION.disable_ama_non_priority_direct_review,
          title: Constants.DISTRIBUTION.disable_ama_non_priority_direct_review_title,
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.boolean,
          value: false,
          unit: '',
          is_disabled_in_ui: true,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion, Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_levers,
          lever_group_order: 103
        },
        {
          item: Constants.DISTRIBUTION.disable_ama_non_priority_evidence_sub,
          title: Constants.DISTRIBUTION.disable_ama_non_priority_evidence_sub_title,
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.boolean,
          value: false,
          unit: '',
          is_disabled_in_ui: true,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion, Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_levers,
          lever_group_order: 104
        },
        {
          item: Constants.DISTRIBUTION.disable_ama_priority_hearing,
          title: Constants.DISTRIBUTION.disable_ama_priority_hearing_title,
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.boolean,
          value: false,
          unit: '',
          is_disabled_in_ui: true,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion, Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_levers,
          lever_group_order: 105
        },
        {
          item: Constants.DISTRIBUTION.disable_ama_priority_direct_review,
          title: Constants.DISTRIBUTION.disable_ama_priority_direct_review_title,
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.boolean,
          value: false,
          unit: '',
          is_disabled_in_ui: true,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion, Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_levers,
          lever_group_order: 106
        },
        {
          item: Constants.DISTRIBUTION.disable_ama_priority_evidence_sub,
          title: Constants.DISTRIBUTION.disable_ama_priority_evidence_sub_title,
          description: '',
          data_type: Constants.ACD_LEVERS.data_types.boolean,
          value: false,
          unit: '',
          is_disabled_in_ui: true,
          algorithms_used: [Constants.ACD_LEVERS.algorithms.proportion, Constants.ACD_LEVERS.algorithms.docket],
          lever_group: Constants.ACD_LEVERS.lever_groups.docket_levers,
          lever_group_order: 107
        },
      ]
    end

    # DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER
    #
    # This is a DANGEROUS OPERATION and only should be done when a lever needs to be completely updated
    #
    # Can pass in a Constants.ACD_LEVERS.data_types or a lever's item value
    #
    # If passing in Constants.ACD_LEVERS.data_types it will fully update all levers with that data_type
    #
    # DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER
    def self.full_update(item)
      levers_to_update = []
      if Constants.ACD_LEVERS.data_types.to_h.values.include?(item)
        levers_to_update = levers.filter { |lever| lever[:data_type] == item}
      else
        levers_to_update = levers.filter { |lever| lever[:item] == item}
      end

      levers_to_update.each do |lever|
        full_update_lever(lever)
      end
    end

    private

    def create_lever(lever)
      lever = CaseDistributionLever.create(
        item: lever[:item],
        title: lever[:title],
        description: lever[:description],
        data_type: lever[:data_type],
        value: lever[:value].to_s,
        unit: lever[:unit],
        is_toggle_active: lever[:is_toggle_active],
        is_disabled_in_ui: lever[:is_disabled_in_ui] || false,
        min_value: lever[:min_value],
        max_value: lever[:max_value],
        algorithms_used: lever[:algorithms_used],
        options: lever[:options],
        control_group: lever[:control_group],
        lever_group: lever[:lever_group],
        lever_group_order: lever[:lever_group_order]
      )

      puts "*********************************************"
      puts lever.errors.full_messages unless lever.valid?
      puts "*********************************************"
    end

    # For properties missing those were intentionally ignored so that they would not
    # be easy to change using this seed data script.
    #
    # The reason being is the properties will either be modified by users, changing them would break the application,
    # or is a JSON object with a complex structure that should be carefully changed
    def update_lever(lever, existing_lever)
      return unless lever_updated?(lever, existing_lever)

      existing_lever.update(
        title: lever[:title],
        description: lever[:description],
        is_toggle_active: lever[:is_toggle_active],
        is_disabled_in_ui: lever[:is_disabled_in_ui],
        unit: lever[:unit],
        min_value: lever[:min_value],
        max_value: lever[:max_value],
        algorithms_used: lever[:algorithms_used],
        control_group: lever[:control_group],
        lever_group_order: lever[:lever_group_order]
      )

      existing_lever.item if existing_lever.valid?
    end

    # For properties missing those were intentionally ignored so that they would not
    # be easy to change using this seed data script.
    #
    # The reason being is the properties will either be modified by users, changing them would break the application,
    # or is a JSON object with a complex structure that should be carefully changed
    def lever_updated?(lever, existing_lever)
      existing_lever.title != lever[:title] ||
      existing_lever.description != lever[:description] ||
      existing_lever.is_toggle_active != lever[:is_toggle_active] ||
      existing_lever.is_disabled_in_ui != lever[:is_disabled_in_ui] ||
      existing_lever.unit != lever[:unit] ||
      existing_lever.min_value != lever[:min_value] ||
      existing_lever.max_value != lever[:max_value] ||
      existing_lever.algorithms_used != lever[:algorithms_used] ||
      existing_lever.control_group != lever[:control_group] ||
      existing_lever.lever_group_order != lever[:lever_group_order]
    end

    def validate_levers_creation
      levers = CaseDistributionLevers.levers.map{ |lever| lever[:item] }
      existing_levers = CaseDistributionLever.all.map(&:item)

      puts "#{CaseDistributionLever.count} levers exist"
      puts "Levers not created #{levers - existing_levers}" if levers.length != existing_levers.length
    end


    # DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER
    #
    # Doesn't update item
    #
    # Updates all fields of a lever
    #
    # This is a DANGEROUS OPERATION and only should be used when a lever needs to be completely updated
    #
    # DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER
    def full_update_lever(lever)
      existing_lever = CaseDistributionLever.find_by_item(item)

      existing_lever.update(
        title: lever[:title],
        description: lever[:description],
        data_type: lever[:data_type],
        value: lever[:value].to_s,
        unit: lever[:unit],
        is_toggle_active: lever[:is_toggle_active],
        is_disabled_in_ui: lever[:is_disabled_in_ui] || false,
        min_value: lever[:min_value],
        max_value: lever[:max_value],
        algorithms_used: lever[:algorithms_used],
        options: lever[:options],
        control_group: lever[:control_group],
        lever_group: lever[:lever_group],
        lever_group_order: lever[:lever_group_order]
      )

      puts "*********************************************"
      puts existing_lever.errors.full_messages unless existing_lever.valid?
      puts "*********************************************"
    end
  end
end
