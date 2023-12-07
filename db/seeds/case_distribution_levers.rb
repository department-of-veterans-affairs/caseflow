module Seeds
  class CaseDistributionLevers < Base
    def seed!
      levers.each do |lever|
        next if CaseDistributionLever.find_by_item(lever[:item])
        create_lever lever
      end
    end

    private

    def create_lever lever
      CaseDistributionLever.create(
        item: lever[:item],
        title: lever[:title],
        description: lever[:description],
        data_type: lever[:data_type],
        value: lever[:value].to_s,
        unit: lever[:unit],
        is_active: lever[:is_active] || false,
        is_disabled: lever[:is_disabled] || false,
        min_value: lever[:min_value],
        max_value: lever[:max_value],
        algorithms_used: lever[:algorithms_used],
        options: lever[:options],
        control_group: lever[:control_group]
      )
    end

    def levers
      [
        {
          item: 'maximum_direct_review_proportion',
          title: 'Maximum Direct Review Proportion',
          description: "Sets the maximum number of direct reviews in relation to due direct review proportion to prevent a complete halt to work on other dockets should demand for direct reviews approach the Board's capacity.",
          data_type: 'number',
          value: 0.07,
          unit: '%',
          is_active: false,
          is_disabled: true,
          min_value: 0,
          max_value: 1,
          algorithms_used: ['proportion']
        },
        {
          item: 'minimum_legacy_proportion',
          title: 'Minimum Legacy Proportion',
          description: 'Sets the minimum proportion of legacy appeals that will be distributed.',
          data_type: 'number',
          value: 0.9,
          unit: '%',
          is_active: false,
          is_disabled: true,
          min_value: 0,
          max_value: 1,
          algorithms_used: ['proportion']
        },
        {
          item: 'nod_adjustment',
          title: 'NOD Adjustment',
          description: 'Applied for docket balancing reflecting the likelihood that HODs will advance to a Form 9.',
          data_type: 'number',
          value: 0.4,
          unit: '%',
          is_active: false,
          is_disabled: true,
          min_value: 0,
          max_value: 1,
          algorithms_used: ['proportion']
        },
        {
          item: 'bust_backlog',
          title: 'Priority Bust Backlog',
          description: 'Distribute legacy cases tied to a judge to the Board-provided limit of 30, regardless of the legacy docket range.',
          data_type: 'boolean',
          value: false,
          unit: '',
          is_active: false,
          is_disabled: true,
          algorithms_used: ['proportion']
        },
        {
          item: 'alternative_batch_size',
          title: 'Alternate Batch Size',
          description: 'Set case-distribution batch size for judges who do not have their own attorney teams.',
          data_type: 'number',
          value: 15,
          unit: 'cases',
          is_active: true,
          is_disabled: false,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['docket', 'proportion']
        },
        {
          item: 'batch_size_per_attorney',
          title: 'Batch Size Per Attorney',
          description: 'Set case distribution batch size for judges with attorney teams. The value for this data element is per attorney.',
          data_type: 'number',
          value: 3,
          unit: 'cases',
          is_active: true,
          is_disabled: false,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['docket', 'proportion']
        },
        {
          item: 'request_more_cases_minimum',
          title: 'Request More Cases Minimum',
          description: 'Set the number of remaining cases a VLJ must have equal to or less than to request more cases. (The number entered is used to equal to or less than.)',
          data_type: 'number',
          value: 8,
          unit: 'cases',
          is_active: true,
          is_disabled: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['docket', 'proportion']
        },
        {
          item: 'ama_hearing_case_affinity_days',
          title: 'AMA Hearing Case Affinity Days',
          description: 'For non-priority AMA Hearing cases, sets the number of days an AMA Hearing Case is tied to the judge that held the hearing.',
          data_type: 'radio',
          value: 'option_1',
          unit: 'days',
          options: [
            {
              item: 'option_1',
              data_type: 'number',
              value: 0,
              text: 'Attempt distribution to current judge for max of:',
              unit: 'days',
              min_value: 0,
              max_value: 100,
            },
            {
              item: 'option_2',
              value: 'option_2',
              text: 'Always distribute to current judge',
            },
            {
              item: 'option_3',
              value: 'option_3',
              text: 'Omit variable from distribution rules',
            }
          ],
          is_active: true,
          is_disabled: false,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['docket']
        },
        {
          item: 'ama_hearing_case_aod_affinity_days',
          title: 'AMA Hearing Case AOD Affinity Days',
          description: 'Sets the number of days an AMA Hearing appeal that is also AOD will respect the affinity to the most-recent hearing judge before distributing the appeal to any available judge.',
          data_type: 'radio',
          value: 'option_1',
          unit: 'days',
          options: [
            {
              item: 'option_1',
              data_type: 'number',
              value: 0,
              text: 'Attempt distribution to current judge for max of:',
              unit: 'days'
            },
            {
              item: 'option_2',
              data_type: '',
              value: 'option_2',
              text: 'Always distribute to current judge',
              unit: ''
            },
            {
              item: 'option_3',
              data_type: '',
              value: 'option_3',
              text: 'Omit variable from distribution rules',
              unit: ''
            }
          ],
          is_active: false,
          is_disabled: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['proportion']
        },
        {
          item: 'cavc_affinity_days',
          title: 'CAVC Affinity Days',
          description: 'Sets the number of days a case returned from CAVC respects the affinity to the judge who authored a decision before distributing the appeal to any available judge. This does not include Legacy CAVC Remand Appeals with a hearing held.',
          data_type: 'radio',
          value: 'option_1',
          unit: 'days',
          options: [
            {
              item: 'option_1',
              data_type: 'number',
              value: 21,
              text: 'Attempt distribution to current judge for max of:',
              unit: 'days'
            },
            {
              item: 'option_2',
              value: 'option_2',
              text: 'Always distribute to current judge'
            },
            {
              item: 'option_3',
              value: 'option_3',
              text: 'Omit variable from distribution rules'
            }
          ],
          is_active: false,
          is_disabled: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['docket', 'proportion']
        },
        {
          item: 'cavc_aod_affinity_days',
          title: 'CAVC AOD Affinity Days',
          description: 'Sets the number of days appeals returned from CAVC that are also AOD respect the affinity to the deciding judge. This is not applicable for legacy apeals for which the deciding judge conducted the most recent hearing.',
          data_type: 'radio',
          value: 'option_1',
          unit: 'days',
          options: [
            {
              item: 'option_1',
              data_type: 'number',
              value: 21,
              text: 'Attempt distribution to current judge for max of:',
              unit: 'days'
            },
            {
              item: 'option_2',
              value: 'option_2',
              text: 'Always distribute to current judge',
            },
            {
              item: 'option_3',
              value: 'option_3',
              text: 'Omit variable from distribution rules',
            }
          ],
          is_active: false,
          is_disabled: true,
          algorithms_used: ['proportion']
        },
        {
          item: 'aoj_affinity_days',
          title: 'AOJ Affinity Days',
          description: 'Sets the number of days an appeal respects the affinity to the deciding judge for Legacy AOJ Remand Returned appeals with no hearing held before distributing the appeal to any available judge.',
          data_type: 'radio',
          value: 'option_1',
          unit: 'days',
          options: [
            {
              item: 'option_1',
              data_type: 'number',
              value: 60,
              text: 'Attempt distribution to current judge for max of:',
              unit: 'days'
            },
            {
              item: 'option_2',
              data_type: '',
              value: 'option_2',
              text: 'Always distribute to current judge',
              unit: ''
            },
            {
              item: 'option_3',
              data_type: '',
              value: 'option_3',
              text: 'Omit variable from distribution rules',
              unit: ''
            }
          ],
          is_active: false,
          is_disabled: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['proportion']
        },
        {
          item: 'aoj_aod_affinity_days',
          title: 'AOJ AOD Affinity Days',
          description: 'Sets the number of days legacy remand Returned appeals that are also AOD (and may or may not have been CAVC at one time) respect the affinity before distributing the appeal to any available jduge. Affects appeals with hearing held when the remanding judge is not the hearing judge, or any legacy AOD + AOD appeal with no hearing held (whether or not it had been CAVC at one time).',
          data_type: 'radio',
          value: 'option_1',
          unit: 'days',
          options: [
            {
              item: 'option_1',
              data_type: 'number',
              value: 14,
              text: 'Attempt distribution to current judge for max of:',
              unit: 'days'
            },
            {
              item: 'option_2',
              data_type: '',
              value: 'option_2',
              text: 'Always distribute to current judge',
              unit: ''
            },
            {
              item: 'option_3',
              data_type: '',
              value: 'option_3',
              text: 'Omit variable from distribution rules',
              unit: ''
            }
          ],
          is_active: false,
          is_disabled: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['proportion']
        },
        {
          item: 'aoj_cavc_affinity_days',
          title: 'AOJ CAVC Affinity Days',
          description: 'Sets the number of days AOJ appeals that were CAVC at some time respect the affinity before the appeal is distributed to any available judge. This applies to any AOJ + CAVC appeal with no hearing held, or those with a hearing held when the remanding judge is not the hearing judge.',
          data_type: 'radio',
          value: 'option_1',
          unit: 'days',
          options: [
            {
              item: 'option_1',
              data_type: 'number',
              value: 21,
              text: 'Attempt distribution to current judge for max of:',
              unit: 'days'
            },
            {
              item: 'option_2',
              data_type: '',
              value: 'option_2',
              text: 'Always distribute to current judge',
              unit: ''
            },
            {
              item: 'option_3',
              data_type: '',
              value: 'option_3',
              text: 'Omit variable from distribution rules',
              unit: ''
            }
          ],
          is_active: true,
          is_disabled: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['docket']
        },
        {
          item: 'ama_hearings_start_distribution_prior_to_goals',
          title: 'AMA Hearings Start Distribution Prior to Goals',
          description: '',
          data_type: 'combination',
          value: 770,
          unit: 'days',
          options: [
            {
              item: 'option_1',
              data_type: 'boolean',
              value: true,
              text: 'This feature is turned on or off',
              unit: ''
            }
          ],
          is_active: true,
          is_disabled: true,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['proportion']
        },
        {
          item: 'ama_direct_review_start_distribution_prior_to_goals',
          title: 'AMA Direct Review Start Distribution Prior to Goals',
          description: '',
          data_type: 'combination',
          value: 365,
          unit: 'days',
          options: [
            {
              item: 'option_1',
              data_type: 'boolean',
              value: true,
              text: 'This feature is turned on or off',
              unit: ''
            }
          ],
          is_active: true,
          is_disabled: false,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['docket']
        },
        {
          item: 'ama_evidence_submission_start_distribution_prior_to_goals',
          title: 'AMA Evidence Submission Start Distribution Prior to Goals',
          description: '',
          data_type: 'combination',
          value: 550,
          unit: 'days',
          options: [
            {
              item: 'option_1',
              data_type: 'boolean',
              value: true,
              text: 'This feature is turned on or off',
              unit: ''
            }
          ],
          is_active: false,
          is_disabled: false,
          min_value: 0,
          max_value: 100,
          algorithms_used: ['proportion']
        },
        {
          item: 'ama_hearings_docket_time_goals',
          title: 'AMA Hearings Docket Time Goals',
          data_type: 'number',
          value: 435,
          unit: 'days',
          is_active: true,
          is_disabled: false,
          min_value: 0,
          max_value: 1000,
          algorithms_used: ['proportion']
        },
        {
          item: 'ama_direct_review_docket_time_goals',
          title: 'AMA Direct Review Docket Time Goals',
          data_type: 'number',
          value: 500,
          unit: 'days',
          is_active: false,
          is_disabled: false,
          min_value: 0,
          max_value: 1000,
          algorithms_used: ['proportion']
        },
        {
          item: 'ama_evidence_submission_docket_time_goals',
          title: 'AMA Evidence Submission Docket Time Goals',
          data_type: 'number',
          value: 123,
          unit: 'days',
          is_active: false,
          is_disabled: true,
          min_value: 0,
          max_value: 1000,
          algorithms_used: ['proportion']
        },
      ]
    end
  end
end
