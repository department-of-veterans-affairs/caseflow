/* eslint-disable max-len */

export const formattedHistory = [
  {
    created_at: 'Fri Jul 07 10:49:07 2023',
    current_values: [6, 5],
    original_values: [3, 8],
    titles: ['Batch Size Per Attorney', 'Request More Cases Minimum'],
    units: ['cases', 'cases'],
    user: 'TEAM_ADMIN (VACO)'
  },
  {
    created_at: 'Mon Jun 05 08:32:55 2023',
    current_values: [30],
    original_values: [21],
    titles: ['AOJ CAVC Affinity Days'],
    units: ['days'],
    user: 'TEAM_ADMIN (VACO)',
  },
  {
    created_at: 'Thu Mar 23 09:21:47 2023',
    current_values: [25, 15],
    original_values: [180, 365],
    titles: ['Alternate Batch Size*', 'AMA Evidence Submission Docket Time Goal'],
    units: ['cases', 'days'],
    user: 'TEAM_ADMIN (VACO)'
  },
  {
    created_at: 'Mon Jun 05 08:32:55 2023',
    current_values: ['Omit variable from distribution rules'],
    original_values: ['Attempt distribution to current judge for max of 25 days'],
    titles: ['CAVC Affinity Days'],
    units: [''],
    user: 'TEAM_ADMIN (VACO)'
  },
];

export const formattedLevers = [
  {
    id: 0,
    item: 'lever_1',
    title: 'Maximum Direct Review Proportion',
    description: "Sets the maximum number of direct reviews in relation to due direct review proportion to prevent a complete halt to work on other dockets should demand for direct reviews approach the Board's capacity.",
    data_type: 'number',
    value: '80',
    unit: '%',
    is_active: false,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    options: [],
    control_group: []
  },
  {
    id: 1,
    item: 'lever_2',
    title: 'Minimum Legacy Proportion',
    description: 'Sets the minimum proportion of legacy appeals that will be distributed.',
    data_type: 'number',
    value: '20',
    unit: '%',
    is_active: false,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    options: [],
    control_group: []
  },
  {
    id: 2,
    item: 'lever_3',
    title: 'NOD Adjustment',
    description: 'Applied for docket balancing reflecting the likelihood that HODs will advance to a Form 9.',
    data_type: 'number',
    value: '90',
    unit: '%',
    is_active: false,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    options: [],
    control_group: []
  },
  {
    id: 3,
    item: 'lever_4',
    title: 'Priority Bust Backlog',
    description: 'Distribute legacy cases tied to a judge to the Board-provided limit of 30, regardless of the legacy docket range.',
    data_type: 'boolean',
    value: true,
    unit: '',
    is_active: false,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    options: [],
    control_group: []
  },
  {
    id: 4,
    item: 'lever_5',
    title: 'Alternate Batch Size*',
    description: 'Set case-distribution batch size for judges who do not have their own attorney teams.',
    data_type: 'number',
    value: '15',
    unit: 'cases',
    is_active: true,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    options: [],
    control_group: []
  },
  {
    id: 5,
    item: 'lever_6',
    title: 'Batch Size Per Attorney*',
    description: 'Set case distribution batch size for judges with attorney teams. The value for this data element is per attorney.',
    data_type: 'number',
    value: '3',
    unit: 'cases',
    is_active: true,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    options: [],
    control_group: []
  },
  {
    id: 6,
    item: 'lever_7',
    title: 'Request More Cases Minimum*',
    description: 'Set the number of remaining cases a VLJ must have equal to or less than to request more cases. (The number entered is used to equal to or less than.)',
    data_type: 'number',
    value: 8,
    unit: 'cases',
    is_active: true,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    options: [],
    control_group: []
  },
  {
    id: 7,
    item: 'lever_8',
    title: 'AMA Hearing Case Affinity Days',
    description: 'For non-priority AMA Hearing cases, sets the number of days an AMA Hearing Case is tied to the judge that held the hearing.',
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
    is_active: true,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    control_group: []
  },
  {
    id: 8,
    item: 'lever_9',
    title: 'AMA Hearing Case AOD Affinity Days',
    description: 'Sets the number of days an AMA Hearing appeal that is also AOD will respect the affinity to the most-recent hearing judge before distributing the appeal to any available judge.',
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
    max_value: 500,
    algorithms_used: [],
    control_group: []
  },
  {
    id: 9,
    item: 'lever_10',
    title: 'CAVC Affinity Days*',
    description: 'Sets the number of days a case returned from CAVC respects the affinity to the judge who authored a decision before distributing the appeal to any available judge. This does not include Legacy CAVC Remand Appeals with a hearing held.',
    data_type: 'radio',
    value: 'option_1',
    unit: 'days',
    options: [
      {
        item: 'option_1',
        data_type: 'number',
        value: '21',
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
    max_value: 500,
    algorithms_used: [],
    control_group: []
  },
  {
    id: 10,
    item: 'lever_11',
    title: 'CAVC AOD Affinity Days',
    description: 'Sets the number of days appeals returned from CAVC that are also AOD respect the affinity to the deciding judge. This is not applicable for legacy apeals for which the deciding judge conducted the most recent hearing.',
    data_type: 'radio',
    value: 'option_1',
    unit: 'days',
    options: [
      {
        item: 'option_1',
        data_type: 'number',
        value: '21',
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
    max_value: 500,
    algorithms_used: [],
    control_group: []
  },
  {
    id: 11,
    item: 'lever_12',
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
    max_value: 500,
    algorithms_used: [],
    control_group: []
  },
  {
    id: 12,
    item: 'lever_13',
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
    max_value: 500,
    algorithms_used: [],
    control_group: []
  },
  {
    id: 13,
    item: 'lever_14',
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
    max_value: 500,
    algorithms_used: [],
    control_group: []
  },
  {
    id: 14,
    item: 'lever_15',
    title: 'AMA Hearings',
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
    is_active: false,
    is_disabled: true,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    control_group: []
  },
  {
    id: 15,
    item: 'lever_16',
    title: 'AMA Direct Review',
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
    max_value: 500,
    algorithms_used: [],
    control_group: []
  },
  {
    id: 16,
    item: 'lever_17',
    title: 'AMA Evidence Submission',
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
    is_disabled: true,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    control_group: []
  },
];

export const updatedLevers = [
  {
    id: 4,
    item: 'lever_5',
    title: 'Alternate Batch Size*',
    description: 'Set case-distribution batch size for judges who do not have their own attorney teams.',
    data_type: 'number',
    value: '30',
    unit: 'cases',
    is_active: true,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    options: [],
    control_group: []
  },
  {
    id: 5,
    item: 'lever_6',
    title: 'Batch Size Per Attorney*',
    description: 'Set case distribution batch size for judges with attorney teams. The value for this data element is per attorney.',
    data_type: 'number',
    value: '6',
    unit: 'cases',
    is_active: true,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    options: [],
    control_group: []
  },
  {
    id: 6,
    item: 'lever_7',
    title: 'Request More Cases Minimum*',
    description: 'Set the number of remaining cases a VLJ must have equal to or less than to request more cases. (The number entered is used to equal to or less than.)',
    data_type: 'number',
    value: 16,
    unit: 'cases',
    is_active: true,
    is_disabled: false,
    min_value: 0,
    max_value: 500,
    algorithms_used: [],
    options: [],
    control_group: []
  },
]
