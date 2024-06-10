/* eslint-disable max-lines */
/* eslint-disable max-len */

export const alternativeBatchSize = {
  item: 'alternative_batch_size',
  title: 'Alternate Batch Size*',
  description: 'Sets case-distribution batch size for judges who do not have their own attorney teams.',
  data_type: 'number',
  value: 15,
  unit: 'cases',
  is_toggle_active: true,
  is_disabled_in_ui: false,
  min_value: 0,
  max_value: null,
  algorithms_used: ['docket', 'proportion'],
  lever_group: 'batch',
  lever_group_order: 2000
};

export const levers = [
  {
    item: 'lever_1',
    title: 'Lever 1',
    description: 'This is the first lever. It is a boolean with the default value of true. Therefore there should be a two radio buttons that display true and false as the example with true being the default option chosen. This lever is active so it should be in the active lever section',
    data_type: 'boolean',
    value: true,
    unit: '',
    is_toggle_active: true,
    lever_group: 'static',
    lever_group_order: 0
  },
  {
    item: 'lever_2',
    title: 'Lever 2',
    description: 'This is the second lever. It is a boolean with the default value of false. Therefore there should be a two radio buttons that display true and false as the example with false being the default option chosen. This lever is active so it should be in the active lever section',
    data_type: 'boolean',
    value: false,
    unit: '',
    is_toggle_active: true,
    lever_group: 'static',
    lever_group_order: 1
  },
  {
    item: 'lever_3',
    title: 'Lever 3',
    description: 'This is the third lever. It is a boolean with the default value of true. Therefore there should be a two radio buttons that display true and false as the example with true being the default option chosen. This lever is inactive so it should be in the inactive lever section',
    data_type: 'boolean',
    value: true,
    unit: '',
    is_toggle_active: false,
    lever_group: 'static',
    lever_group_order: 2
  },
  {
    item: 'lever_4',
    title: 'Lever 4',
    description: 'This is the fourth lever. It is a boolean with the default value of false. Therefore there should be a two radio buttons that display true and false as the example with false being the default option chosen. This lever is inactive so it should be in the inactive lever section',
    data_type: 'boolean',
    value: false,
    unit: '',
    is_toggle_active: true,
    lever_group: 'static',
    lever_group_order: 3
  },
  {
    item: 'lever_5',
    title: 'Lever 5',
    description: "This is the fifth lever. It is a number data type with the default value of 42. Therefore there should be a number input that displays 42 and 'days' as the unit. This lever is active so it should be in the active lever section",
    data_type: 'number',
    value: 42,
    unit: 'Days',
    is_toggle_active: true,
    lever_group: 'static',
    lever_group_order: 4
  },
  {
    item: 'lever_6',
    title: 'Lever 6',
    description: "This is the fifth lever. It is a number data type with the default value of 15. Therefore '15 days' should be displayed. This lever is inactive so it should be in the inactive lever section",
    data_type: 'number',
    value: 15,
    unit: 'Days',
    is_toggle_active: false,
    lever_group: 'static',
    lever_group_order: 5
  },
  {
    item: 'lever_7',
    title: 'Lever 7',
    description: "This is the seventh lever. It is a number data type with the default value of 35. Therefore there should be a number input that displays 35 and 'cases' as the unit. This lever is active so it should be in the active lever section",
    data_type: 'number',
    value: 35,
    unit: 'Cases',
    is_toggle_active: true,
    lever_group: 'static',
    lever_group_order: 6
  },
  {
    item: 'lever_8',
    title: 'Lever 8',
    description: "This is the eigth lever. It is a number data type with the default value of 200. Therefore '200 cases' should be displayed. This lever is inactive so it should be in the inactive lever section",
    data_type: 'number',
    value: 200,
    unit: 'Cases',
    is_toggle_active: false,
    lever_group: 'static',
    lever_group_order: 7
  },
  {
    item: 'lever_9',
    title: 'Lever 9',
    description: 'This is the ninth lever. It is a radio data type with the default value of option_1. Therefore there should be a radio options displayed and option_1 is selected by default. If the option is text only the text is displayed, but if it is a different data type then the appropriate input and unit are displayed and the value stored. This lever is active so it should be in the active lever section',
    data_type: 'radio',
    value: 'option_1',
    unit: 'Cases',
    options: [
      {
        item: 'option_1',
        data_type: 'text',
        value: 'option_1',
        text: 'Option 1',
        unit: ''
      },
      {
        item: 'option_2',
        data_type: 'number',
        value: 68,
        text: 'Option 2',
        unit: 'Days'
      }
    ],
    is_toggle_active: true,
    lever_group: 'static',
    lever_group_order: 8
  },
  {
    item: 'lever_10',
    title: 'Lever 10',
    description: 'This is the ninth lever. It is a radio data type with the default value of option_1. Therefore there should be a radio options displayed and option_1 is selected by default. If the option is text only the text is displayed, but if it is a different data type then the appropriate input and unit are displayed and the value stored. This lever is active so it should be in the active lever section',
    data_type: 'combination',
    value: 78,
    unit: 'Cases',
    options: [
      {
        item: 'option_1',
        data_type: 'boolean',
        value: true,
        text: 'This feature is turned on or off',
        unit: ''
      }
    ],
    is_toggle_active: true,
    lever_group: 'static',
    lever_group_order: 9
  },
  {
    item: 'lever_11',
    title: 'Lever 11',
    description: 'This is the ninth lever. It is a radio data type with the default value of option_1. Therefore there should be a radio options displayed and option_1 is selected by default. If the option is text only the text is displayed, but if it is a different data type then the appropriate input and unit are displayed and the value stored. This lever is active so it should be in the active lever section',
    data_type: 'combination',
    value: 50,
    unit: 'Days',
    options: [
      {
        item: 'option_1',
        data_type: 'boolean',
        value: false,
        text: 'This feature is turned on or off',
        unit: ''
      }
    ],
    is_toggle_active: false,
    lever_group: 'static',
    lever_group_order: 10
  },
  {
    item: 'lever_12',
    title: 'Lever 12',
    description: 'This is the ninth lever. It is a radio data type with the default value of option_1. Therefore there should be a radio options displayed and option_1 is selected by default. If the option is text only the text is displayed, but if it is a different data type then the appropriate input and unit are displayed and the value stored. This lever is active so it should be in the active lever section',
    data_type: 'combination',
    value: 50,
    unit: 'Days',
    options: [
      {
        item: 'option_1',
        data_type: 'boolean',
        value: false,
        text: 'This feature is turned on or off',
        unit: ''
      }
    ],
    is_toggle_active: false,
    is_disabled_in_ui: true,
    lever_group: 'static',
    lever_group_order: 11
  },
  {
    item: 'lever_13',
    title: 'Lever 13',
    description: 'This is the ninth lever. It is a radio data type with the default value of option_1. Therefore there should be a radio options displayed and option_1 is selected by default. If the option is text only the text is displayed, but if it is a different data type then the appropriate input and unit are displayed and the value stored. This lever is active so it should be in the active lever section',
    data_type: 'radio',
    value: 'option_1',
    unit: 'Cases',
    options: [
      {
        item: 'option_1',
        data_type: 'text',
        value: 'option_1',
        text: 'Option 1',
        unit: ''
      },
      {
        item: 'option_2',
        data_type: 'number',
        value: 68,
        text: 'Option 2',
        unit: 'Days'
      },
      {
        item: 'option_3',
        text: 'Option 3',
      }
    ],
    is_toggle_active: true,
    is_disabled_in_ui: true,
    lever_group: 'static',
    lever_group_order: 12
  },
  {
    ...alternativeBatchSize
  },
];

export const history = [
  {
    user: 'john_smith',
    created_at: '2023-07-01 10:10:01',
    title: 'Lever 1',
    original_value: 10,
    current_value: 23,
    unit: 'cases'
  },
  {
    user: 'john_smith',
    created_at: '2023-07-01 10:10:01',
    title: 'Lever 2',
    original_value: false,
    current_value: true,
    unit: ''
  },
  {
    user: 'jane_smith',
    created_at: '2023-07-01 12:10:01',
    title: 'Lever 1',
    original_value: 5,
    current_value: 42,
    unit: 'cases'
  }
];

export const formattedHistory = [
  {
    user_name: 'john_smith',
    created_at: '2023-07-01 10:10:01',
    lever_title: 'Lever 1',
    original_value: 10,
    current_value: 23
  },
  {
    user_name: 'john_smith',
    created_at: '2023-07-01 10:10:01',
    lever_title: 'Lever 2',
    original_value: false,
    current_value: true
  },
  {
    user_name: 'jane_smith',
    created_at: '2023-07-01 12:10:01',
    lever_title: 'Lever 1',
    original_value: 5,
    current_value: 42
  }
];

/* Reducer Test Data */
export const historyList = formattedHistory;

/* END Reducer Test Data */

/* Outlier Test Data for Testing Coverage */

export const unknownDataTypeStaticLevers = [
  {
    item: 'lever_unknown_dt_static',
    title: 'lever_unknown_dt_static_title',
    description: 'lever_unknown_dt_static_desc',
    data_type: '',
    value: 'test-value-unknown-dt-static',
    unit: 'test-unit-unknown-dt-static',
    is_toggle_active: true,
    lever_group: 'static',
    lever_group_order: 0
  }
];

export const mockDocketDistributionPriorLevers = [
  {
    item: 'ama_hearing_start_distribution_prior_to_goals',
    title: 'AMA Hearings Start Distribution Prior to Goals',
    description: '',
    data_type: 'combination',
    value: 40,
    unit: 'days',
    options: [
      {
        item: 'value',
        data_type: 'boolean',
        value: true,
        text: 'This feature is turned on or off',
        unit: ''
      }
    ],
    is_toggle_active: false,
    is_disabled_in_ui: true,
    min_value: 0,
    max_value: 100,
    algorithms_used: ['proportion'],
    lever_group: 'docket_distribution_prior',
    lever_group_order: 4000
  },
  {
    item: 'ama_direct_review_start_distribution_prior_to_goals',
    title: 'AMA Direct Review Start Distribution Prior to Goals',
    description: '',
    data_type: 'combination',
    value: 770,
    unit: 'days',
    options: [
      {
        item: 'value',
        data_type: 'boolean',
        value: true,
        text: 'This feature is turned on or off',
        unit: ''
      }
    ],
    is_toggle_active: false,
    is_disabled_in_ui: true,
    min_value: 0,
    max_value: 100,
    algorithms_used: ['proportion'],
    lever_group: 'docket_distribution_prior',
    lever_group_order: 4001
  }
];
// Batch Lever with Higher Min value for testing errors 'out of bounds'
export const mockBatchLevers = [
  {
    item: 'test-lever',
    title: 'Test Title Lever*',
    description: 'Test Description for Lever data outOfBoundsBatchLever.',
    data_type: 'number',
    value: 5,
    unit: 'cases',
    is_toggle_active: true,
    is_disabled_in_ui: false,
    min_value: 5,
    max_value: null,
    algorithms_used: ['docket', 'proportion'],
    lever_group: 'batch',
    lever_group_order: 2000
  },
  {
    item: 'test-lever-disabled',
    title: 'Test Title Lever2*',
    description: 'Test Description for Lever data disabled-in-ui.',
    data_type: 'number',
    value: 5,
    unit: 'cases',
    is_toggle_active: true,
    is_disabled_in_ui: true,
    min_value: 5,
    max_value: null,
    algorithms_used: ['docket', 'proportion'],
    lever_group: 'batch',
    lever_group_order: 2001
  },
  {
    item: 'test-lever-text-type',
    title: 'Test Text Title Lever3',
    description: 'Test Description for Lever data type text',
    data_type: 'text',
    value: 10,
    unit: 'cases',
    is_toggle_active: true,
    is_disabled_in_ui: true,
    min_value: 5,
    max_value: null,
    algorithms_used: ['docket', 'proportion'],
    lever_group: 'batch',
    lever_group_order: 2002
  },
];

export const testingBatchLeversUpdatedToSave = [
  {
    item: 'test-lever',
    title: 'Test Title Lever*',
    description: 'Test Description',
    data_type: 'number',
    value: 24,
    unit: 'cases',
    is_toggle_active: true,
    is_disabled_in_ui: false,
    min_value: 5,
    max_value: null,
    algorithms_used: ['docket', 'proportion'],
    lever_group: 'batch',
    lever_group_order: 2000
  },
  {
    item: 'test-lever-disabled',
    title: 'Test Title Lever2*',
    description: 'Test Description for Lever data disabled-in-ui.',
    data_type: 'number',
    value: 5,
    unit: 'cases',
    is_toggle_active: true,
    is_disabled_in_ui: true,
    min_value: 5,
    max_value: null,
    algorithms_used: ['docket', 'proportion'],
    lever_group: 'batch',
    lever_group_order: 2001
  },
];

export const mockDocketTimeGoalsLevers = [
  {
    item: 'ama_hearing_docket_time_goals',
    title: 'AMA Hearings Docket Time Goals',
    data_type: 'number',
    value: 365,
    unit: 'days',
    is_toggle_active: false,
    is_disabled_in_ui: true,
    min_value: 0,
    max_value: 888,
    algorithms_used: ['docket'],
    lever_group: 'docket_time_goal',
    lever_group_order: 4003
  },
  {
    item: 'ama_direct_review_docket_time_goals',
    title: 'AMA Direct Review Docket Time Goals',
    data_type: 'number',
    value: 365,
    unit: 'days',
    is_toggle_active: false,
    is_disabled_in_ui: true,
    min_value: 0,
    max_value: 888,
    algorithms_used: ['docket'],
    lever_group: 'docket_time_goal',
    lever_group_order: 4004
  },
];

// Affinity days Lever with Higher Min value for testing errors 'out of bounds'
export const mockAffinityDaysLevers = [
  {
    item: 'ama_hearing_case_affinity_days',
    title: 'AMA Hearing Case Affinity Days',
    description: 'For non-priority AMA Hearing cases, sets the number of days an AMA Hearing Case is tied to the judge that held the hearing.',
    data_type: 'radio',
    value: 0,
    unit: 'days',
    options: [
      {
        item: 'value',
        data_type: 'number',
        value: 0,
        text: 'Attempt distribution to current judge for max of:',
        unit: 'days',
        min_value: 0,
        max_value: 100,
        selected: true
      },
      {
        item: 'infinite',
        value: 'infinite',
        text: 'Always distribute to current judge',
        selected: false
      },
      {
        item: 'omit',
        value: 'omit',
        text: 'Omit variable from distribution rules',
        selected: false
      }
    ],
    is_toggle_active: false,
    is_disabled_in_ui: true,
    min_value: 0,
    max_value: 100,
    algorithms_used: ['docket'],
    lever_group: 'affinity',
    lever_group_order: 3000
  },
  {
    item: 'ama_hearing_case_aod_affinity_days',
    title: 'AMA Hearing Case AOD Affinity Days',
    description: 'Sets the number of days an AMA Hearing appeal that is also AOD will respect the affinity to the most-recent hearing judge before distributing the appeal to any available judge.',
    data_type: 'radio',
    value: 'infinite',
    unit: 'days',
    options: [
      {
        item: 'value',
        data_type: 'text',
        value: 'test',
        text: 'Attempt distribution to current judge for max of:',
        unit: 'days',
        selected: false
      },
      {
        item: 'infinite',
        data_type: '',
        value: 'infinite',
        text: 'Always distribute to current judge',
        unit: '',
        selected: true
      },
      {
        item: 'omit',
        data_type: '',
        value: 'omit',
        text: 'Omit variable from distribution rules',
        unit: '',
        selected: false
      }
    ],
    is_toggle_active: false,
    is_disabled_in_ui: true,
    min_value: 0,
    max_value: 100,
    algorithms_used: ['proportion'],
    lever_group: 'affinity',
    lever_group_order: 3001
  }
];

export const mockStaticLevers = [
  {
    id: 1,
    algorithms_used: [
      'proportion'
    ],
    control_group: null,
    created_at: '2024-01-24T11:52:10.126-05:00',
    data_type: 'number',
    description: "Sets the maximum number of direct reviews in relation to due direct review proportion to prevent a complete halt to work on other dockets should demand for direct reviews approach the Board's capacity.",
    is_disabled_in_ui: true,
    is_toggle_active: false,
    item: 'maximum_direct_review_proportion',
    lever_group: 'static',
    lever_group_order: 1000,
    max_value: null,
    min_value: 0,
    options: null,
    title: 'Maximum Direct Review Proportion',
    unit: '%',
    updated_at: '2024-01-24T11:52:10.126-05:00',
    value: '0.8',
    backendValue: '0.8'
  },
  {
    id: 2,
    algorithms_used: [
      'proportion'
    ],
    control_group: null,
    created_at: '2024-01-24T11:52:10.132-05:00',
    data_type: 'number',
    description: 'Sets the minimum proportion of legacy appeals that will be distributed.',
    is_disabled_in_ui: true,
    is_toggle_active: false,
    item: 'minimum_legacy_proportion',
    lever_group: 'static',
    lever_group_order: 1001,
    max_value: null,
    min_value: 0,
    options: null,
    title: 'Minimum Legacy Proportion',
    unit: '%',
    updated_at: '2024-01-24T11:52:10.132-05:00',
    value: '0.2',
    backendValue: '0.2'
  },
  {
    id: 3,
    algorithms_used: [
      'proportion'
    ],
    control_group: null,
    created_at: '2024-01-24T11:52:10.137-05:00',
    data_type: 'number',
    description: 'Applied for docket balancing reflecting the likelihood that NODs will advance to a Form 9.',
    is_disabled_in_ui: true,
    is_toggle_active: false,
    item: 'nod_adjustment',
    lever_group: 'static',
    lever_group_order: 1002,
    max_value: null,
    min_value: 0,
    options: null,
    title: 'NOD Adjustment',
    unit: '%',
    updated_at: '2024-01-24T11:52:10.137-05:00',
    value: '0.9',
    backendValue: '0.9'
  },
  {
    id: 4,
    algorithms_used: [
      'proportion'
    ],
    control_group: null,
    created_at: '2024-01-24T11:52:10.143-05:00',
    data_type: 'boolean',
    description: 'Distribute legacy cases tied to a judge to the Board-provided limit of 30, regardless of the legacy docket range.',
    is_disabled_in_ui: true,
    is_toggle_active: false,
    item: 'bust_backlog',
    lever_group: 'static',
    lever_group_order: 1003,
    max_value: null,
    min_value: null,
    options: null,
    title: 'Priority Bust Backlog',
    unit: '',
    updated_at: '2024-01-24T11:52:10.143-05:00',
    value: 'true',
    backendValue: 'true'
  }
];

export const mockReturnedOption = {
  item: 'option_1',
  data_type: 'number',
  value: 0,
  text: 'Attempt distribution to current judge for max of:',
  unit: 'days',
  min_value: 0,
  max_value: 100
};

export const mockHistoryPayload = [
  {
    case_distribution_lever_id: 5,
    created_at: '2024-01-12T16:48:35.422-05:00',
    id: 27,
    lever_data_type: 'number',
    lever_title: 'Alternate Batch Size*',
    lever_unit: 'cases',
    previous_value: '15',
    update_value: '70',
    user_css_id: 'BVADWISE'
  }
];

export const mockDocketDistributionPriorLeversReturn = [
  {
    item: 'ama_hearing_start_distribution_prior_to_goals',
    title: 'AMA Hearings Start Distribution Prior to Goals',
    description: '',
    data_type: 'combination',
    value: 40,
    unit: 'days',
    options: [
      {
        item: 'value',
        data_type: 'boolean',
        value: true,
        text: 'This feature is turned on or off',
        unit: ''
      }
    ],
    is_toggle_active: false,
    is_disabled_in_ui: true,
    min_value: 0,
    max_value: 100,
    algorithms_used: ['proportion'],
    lever_group: 'docket_distribution_prior',
    lever_group_order: 4000
  },
  {
    item: 'ama_direct_review_start_distribution_prior_to_goals',
    title: 'AMA Direct Review Start Distribution Prior to Goals',
    description: '',
    data_type: 'combination',
    value: 770,
    unit: 'days',
    options: [
      {
        item: 'value',
        data_type: 'boolean',
        value: true,
        text: 'This feature is turned on or off',
        unit: ''
      }
    ],
    is_toggle_active: false,
    is_disabled_in_ui: true,
    min_value: 0,
    max_value: 100,
    algorithms_used: ['proportion'],
    lever_group: 'docket_distribution_prior',
    lever_group_order: 4001
  }
];
export const mockCombinationReturn = {
  item: 'ama_hearing_start_distribution_prior_to_goals',
  title: 'AMA Hearings Start Distribution Prior to Goals',
  description: '',
  data_type: 'combination',
  value: 40,
  unit: 'days',
  options: [
    {
      item: 'value',
      data_type: 'boolean',
      value: true,
      text: 'This feature is turned on or off',
      unit: ''
    }
  ],
  // eslint-disable-next-line no-undefined
  is_toggle_active: undefined,
  is_disabled_in_ui: true,
  min_value: 0,
  max_value: 100,
  algorithms_used: ['proportion'],
  lever_group: 'docket_distribution_prior',
  lever_group_order: 4000
};

export const mockAffinityDaysLeversReturn = [
  {
    item: 'ama_hearing_case_affinity_days',
    title: 'AMA Hearing Case Affinity Days',
    description: 'For non-priority AMA Hearing cases, sets the number of days an AMA Hearing Case is tied to the judge that held the hearing.',
    data_type: 'radio',
    value: 80,
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
        selected: true
      },
      {
        item: 'infinite',
        value: 'infinite',
        text: 'Always distribute to current judge'
      },
      {
        item: 'omit',
        value: 'omit',
        text: 'Omit variable from distribution rules'
      }
    ],
    is_toggle_active: false,
    is_disabled_in_ui: true,
    min_value: 0,
    max_value: 100,
    algorithms_used: ['docket'],
    lever_group: 'affinity',
    lever_group_order: 3000
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
        data_type: 'text',
        value: 'test',
        text: 'Attempt distribution to current judge for max of:',
        unit: 'days'
      },
      {
        item: 'infinite',
        data_type: '',
        value: 'infinite',
        text: 'Always distribute to current judge',
        unit: ''
      },
      {
        item: 'omit',
        data_type: '',
        value: 'omit',
        text: 'Omit variable from distribution rules',
        unit: ''
      }
    ],
    is_toggle_active: false,
    is_disabled_in_ui: true,
    min_value: 0,
    max_value: 100,
    algorithms_used: ['proportion'],
    lever_group: 'affinity',
    lever_group_order: 3001
  }
];

export const mockTextLeverReturn = [
  {
    item: 'test-lever',
    title: 'Test Title Lever*',
    description: 'Test Description for Lever data outOfBoundsBatchLever.',
    data_type: 'number',
    value: 5,
    unit: 'cases',
    is_toggle_active: true,
    is_disabled_in_ui: false,
    min_value: 5,
    max_value: null,
    algorithms_used: ['docket', 'proportion'],
    lever_group: 'batch',
    lever_group_order: 2000
  },
  {
    item: 'test-lever-disabled',
    title: 'Test Title Lever2*',
    description: 'Test Description for Lever data disabled-in-ui.',
    data_type: 'number',
    value: 5,
    unit: 'cases',
    is_toggle_active: true,
    is_disabled_in_ui: true,
    min_value: 5,
    max_value: null,
    algorithms_used: ['docket', 'proportion'],
    lever_group: 'batch',
    lever_group_order: 2001
  },
  {
    item: 'test-lever-text-type',
    title: 'Test Text Title Lever3',
    description: 'Test Description for Lever data type text',
    data_type: 'text',
    value: 10,
    unit: 'cases',
    is_toggle_active: true,
    is_disabled_in_ui: true,
    min_value: 5,
    max_value: null,
    algorithms_used: ['docket', 'proportion'],
    lever_group: 'batch',
    lever_group_order: 2002
  },
  {
    item: 'test-lever-text-type',
    title: 'Test Text Title Lever3',
    description: 'Test Description for Lever data type text',
    data_type: 'text',
    value: 78,
    unit: 'cases',
    is_toggle_active: true,
    is_disabled_in_ui: true,
    min_value: 5,
    max_value: null,
    algorithms_used: ['docket', 'proportion'],
    lever_group: 'batch',
    lever_group_order: 2003
  }
];

export const mockDocketLevers = [
  {
    item: 'disable_ama_priority_legacy',
    title: 'Test Docket Lever Title 1',
    description: '',
    data_type: 'boolean',
    value: false,
    unit: '',
    is_disabled_in_ui: false,
    algorithms_used: ['proportion', 'docket'],
    lever_group: 'docket_levers',
    lever_group_order: 100,
    control_group: 'priority',
    options: [
      {
        displayText: 'On',
        name: 'disable_ama_priority_legacy',
        value: 'true',
        disabled: false
      },
      {
        displayText: 'Off',
        name: 'disable_ama_priority_legacy',
        value: 'false',
        disabled: false
      }
    ]
  },
  {
    item: 'disable_ama_priority_direct_review',
    title: 'Test Docket Lever Title 2',
    description: '',
    data_type: 'boolean',
    value: false,
    unit: '',
    is_disabled_in_ui: false,
    algorithms_used: ['proportion', 'docket'],
    lever_group: 'docket_levers',
    lever_group_order: 101,
    control_group: 'priority',
    options: [
      {
        displayText: 'On',
        name: 'disable_ama_priority_direct_review',
        value: 'true',
        disabled: false
      },
      {
        displayText: 'Off',
        name: 'disable_ama_priority_direct_review',
        value: 'false',
        disabled: false
      }
    ]
  },
  {
    item: 'disable_ama_priority_hearing',
    title: 'Test Docket Lever Title 3',
    description: '',
    data_type: 'boolean',
    value: false,
    unit: '',
    is_disabled_in_ui: false,
    algorithms_used: ['proportion', 'docket'],
    lever_group: 'docket_levers',
    lever_group_order: 102,
    control_group: 'priority',
    options: [
      {
        displayText: 'On',
        name: 'disable_ama_priority_hearing',
        value: 'true',
        disabled: false
      },
      {
        displayText: 'Off',
        name: 'disable_ama_priority_hearing',
        value: 'false',
        disabled: false
      }
    ]
  },
  {
    item: 'disable_ama_priority_evidence_submission',
    title: 'Test Docket Lever Title 4',
    description: '',
    data_type: 'boolean',
    value: false,
    unit: '',
    is_disabled_in_ui: false,
    algorithms_used: ['proportion', 'docket'],
    lever_group: 'docket_levers',
    lever_group_order: 103,
    control_group: 'priority',
    options: [
      {
        displayText: 'On',
        name: 'disable_ama_priority_evidence_submission',
        value: 'true',
        disabled: false
      },
      {
        displayText: 'Off',
        name: 'disable_ama_priority_evidence_submission',
        value: 'false',
        disabled: false
      }
    ]
  },
  {
    item: 'disable_ama_non_priority_legacy',
    title: 'Test Docket Lever Title 5',
    description: '',
    data_type: 'boolean',
    value: false,
    unit: '',
    is_disabled_in_ui: false,
    algorithms_used: ['proportion', 'docket'],
    lever_group: 'docket_levers',
    lever_group_order: 104,
    control_group: 'non-priority',
    options: [
      {
        displayText: 'On',
        name: 'disable_ama_non_priority_legacy',
        value: 'true',
        disabled: false
      },
      {
        displayText: 'Off',
        name: 'disable_ama_non_priority_legacy',
        value: 'false',
        disabled: false
      }
    ]
  },
  {
    item: 'disable_ama_non_priority_direct_review',
    title: 'Test Docket Lever Title 6',
    description: '',
    data_type: 'boolean',
    value: true,
    unit: '',
    is_disabled_in_ui: false,
    algorithms_used: ['proportion', 'docket'],
    lever_group: 'docket_levers',
    lever_group_order: 105,
    control_group: 'non-priority',
    options: [
      {
        displayText: 'On',
        name: 'disable_ama_non_priority_direct_review',
        value: 'true',
        disabled: false
      },
      {
        displayText: 'Off',
        name: 'disable_ama_non_priority_direct_review',
        value: 'false',
        disabled: false
      }
    ]
  },
  {
    item: 'disable_ama_non_priority_hearing',
    title: 'Test Docket Lever Title 7',
    description: '',
    data_type: 'boolean',
    value: false,
    unit: '',
    is_disabled_in_ui: false,
    algorithms_used: ['proportion', 'docket'],
    lever_group: 'docket_levers',
    lever_group_order: 106,
    control_group: 'non-priority',
    options: [
      {
        displayText: 'On',
        name: 'disable_ama_non_priority_hearing',
        value: 'true',
        disabled: false
      },
      {
        displayText: 'Off',
        name: 'disable_ama_non_priority_hearing',
        value: 'false',
        disabled: false
      }
    ]
  },
  {
    item: 'disable_ama_non_priority_evidence_submission',
    title: 'Test Docket Lever Title 8',
    description: '',
    data_type: 'boolean',
    value: false,
    unit: '',
    is_disabled_in_ui: false,
    algorithms_used: ['proportion', 'docket'],
    lever_group: 'docket_levers',
    lever_group_order: 107,
    control_group: 'non-priority',
    options: [
      {
        displayText: 'On',
        name: 'disable_ama_non_priority_evidence_submission',
        value: 'true',
        disabled: false
      },
      {
        displayText: 'Off',
        name: 'disable_ama_non_priority_evidence_submission',
        value: 'false',
        disabled: false
      }
    ]
  },
];
