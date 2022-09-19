/* eslint-disable max-lines */
export const uiData = {
  ui: {
    highlightFormItems: false,
    messages: {
      success: null,
      error: null
    },
    saveState: {
      savePending: false,
      saveSuccessful: null
    },
    featureToggles: {
      vha_irregular_appeals: true
    }
  }
};

/* eslint-disable max-len */
const caregiverActions = [
  {
    func: 'vha_caregiver_support_mark_task_in_progress',
    label: 'Mark task in progress',
    value: 'modal/mark_task_in_progress',
    data: {
      modal_title: 'Mark task as in progress',
      modal_body: 'By marking task as in progress, you are confirming that you are actively working on collecting documents for this appeal.\n\nOnce marked, other members of your organization will no longer be able to mark this task as in progress.',
      modal_button_text: 'Mark in progress',
      message_title: 'You have successfully marked Bob Smithswift\'s case as in progress',
      type: 'VhaDocumentSearchTask',
      redirect_after: '/organizations/vha-csp?tab=caregiver_support_in_progress'
    }
  },
  {
    func: 'vha_caregiver_support_send_to_board_intake_for_review',
    label: 'Documents ready for Board Intake review',
    value: 'modal/vha_caregiver_support_send_to_board_intake_for_review',
    data: {
      modal_title: 'Ready for Review',
      modal_button_text: 'Send',
      message_title: 'You have successfully sent Bob Smithswift\'s case to Board Intake for Review',
      type: 'VhaDocumentSearchTask',
      redirect_after: '/organizations/vha-csp?tab=caregiver_support_completed',
      body_optional: true
    }
  },
  {
    func: 'vha_caregiver_support_return_to_board_intake',
    label: 'Return to Board Intake',
    value: 'modal/vha_caregiver_support_return_to_board_intake',
    data: {
      modal_title: 'Return to Board Intake',
      modal_body: 'This appeal will be returned to Board intake.',
      modal_button_text: 'Return',
      type: 'VhaDocumentSearchTask',
      options: [
        {
          label: 'Duplicate',
          value: 'Duplicate'
        },
        {
          label: 'HLR Pending',
          value: 'HLR Pending'
        },
        {
          label: 'SC Pending',
          value: 'SC Pending'
        },
        {
          label: 'Not PCAFC related',
          value: 'Not PCAFC related'
        },
        {
          label: 'No PCAFC decisions for this individual',
          value: 'no PCAFC decisions for this individual'
        },
        {
          label: 'No PCAFC decision for identified time period',
          value: 'No PCAFC decision for identified time period'
        },
        {
          label: 'Multiple PCAFC decisions could apply',
          value: 'Multiple PCAFC decisions could apply'
        },
        {
          label: 'Other',
          value: 'other'
        }
      ],
      redirect_after: '/organizations/vha-csp?tab=caregiver_support_completed'
    }
  }
];

const vhaDocumentSearchTaskData = {
  7119: {
    uniqueId: '7119',
    isLegacy: false,
    type: 'VhaDocumentSearchTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1632,
    externalAppealId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
    assignedOn: '2022-08-08T22:11:55.277-04:00',
    closestRegionalOffice: null,
    createdAt: '2022-08-02T12:03:32.187-04:00',
    closedAt: null,
    startedAt: null,
    assigneeName: 'VHA CAMO',
    assignedTo: {
      cssId: null,
      name: 'VHA CAMO',
      id: 31,
      isOrganization: true,
      type: 'VhaCamo'
    },
    assignedBy: {
      firstName: 'Ignacio',
      lastName: 'Shaw',
      cssId: 'BVAISHAW',
      pgId: 18
    },
    cancelledBy: {
      cssId: null
    },
    cancelReason: null,
    convertedBy: {
      cssId: null
    },
    convertedOn: null,
    taskId: '7119',
    status: 'assigned',
    instructions: [],
    availableActions: [
      {
        func: 'vha_assign_to_program_office_data',
        label: 'Assign to Program Office',
        value: 'modal/assign_to_program_office',
        data: {
          options: [
            {
              label: 'Community Care - Payment Operations Management',
              value: 33
            },
            {
              label: 'Community Care - Veteran and Family Members Program',
              value: 34
            },
            {
              label: 'Member Services - Health Eligibility Center',
              value: 35
            },
            {
              label: 'Member Services - Beneficiary Travel',
              value: 36
            },
            {
              label: 'Prosthetics',
              value: 37
            }
          ],
          modal_title: 'Assign to Program Office',
          modal_body: 'Provide instructions and context for this action:',
          modal_button_text: 'Assign',
          modal_selector_placeholder: 'Select Program Office',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/vha-camo'
        }
      },
      {
        func: 'vha_send_to_board_intake',
        label: 'Send to Board Intake',
        value: 'modal/vha_send_to_board_intake',
        data: {
          modal_title: 'Send to Board Intake',
          modal_button_text: 'Send',
          type: 'VhaDocumentSearchTask',
          redirect_after: '/organizations/vha-camo'
        }
      }
    ],
    timelineTitle: 'VhaDocumentSearchTask completed'
  }
};

const educationDocumentSearchTaskData = {
  7162: {
    uniqueId: '7162',
    isLegacy: false,
    type: 'EducationDocumentSearchTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1647,
    externalAppealId: 'adfd7d18-f848-4df5-9df2-9ca43c58dd13',
    assignedOn: '2022-08-28T12:35:50.482-04:00',
    closestRegionalOffice: null,
    createdAt: '2022-08-28T12:35:50.482-04:00',
    closedAt: null,
    startedAt: null,
    assigneeName: 'Executive Management Office',
    assignedTo: {
      cssId: null,
      name: 'Executive Management Office',
      id: 56,
      isOrganization: true,
      type: 'EducationEmo'
    },
    assignedBy: {
      firstName: 'Deborah',
      lastName: 'Wise',
      cssId: 'BVADWISE',
      pgId: 17
    },
    cancelledBy: {
      cssId: null
    },
    cancelReason: null,
    convertedBy: {
      cssId: null
    },
    convertedOn: null,
    taskId: '7162',
    parentId: 7161,
    label: 'Review Documentation',
    documentId: null,
    externalHearingId: null,
    workProduct: null,
    previousTaskAssignedOn: null,
    placedOnHoldAt: null,
    status: 'assigned',
    onHoldDuration: null,
    instructions: [],
    decisionPreparedBy: null,
    availableActions: [
      {
        func: 'emo_assign_to_education_rpo_data',
        label: 'Assign to Regional Processing Office',
        value: 'modal/emo_assign_to_education_rpo',
        data: {
          options: [
            {
              label: 'Buffalo RPO',
              value: 57
            },
            {
              label: 'Central Office RPO',
              value: 58
            },
            {
              label: 'Muskogee RPO',
              value: 59
            }
          ],
          modal_title: 'Assign to RPO',
          modal_body: 'Provide instructions and context for this action:',
          modal_selector_placeholder: 'Select RPO',
          type: 'EducationAssessDocumentationTask',
          redirect_after: '/organizations/edu-emo',
          body_optional: true
        }
      },
      {
        func: 'emo_return_to_board_intake',
        label: 'Return to Board Intake',
        value: 'modal/emo_return_to_board_intake',
        data: {
          modal_title: 'Return to Board Intake',
          modal_button_text: 'Return',
          type: 'EducationDocumentSearchTask',
          redirect_after: '/organizations/edu-emo'
        }
      },
      {
        func: 'emo_send_to_board_intake_for_review',
        label: 'Ready for Review',
        value: 'modal/emo_send_to_board_intake_for_review',
        data: {
          modal_title: 'Ready for Review',
          modal_button_text: 'Send',
          type: 'EducationDocumentSearchTask',
          redirect_after: '/organizations/edu-emo',
          body_optional: true
        }
      }
    ],
    timelineTitle: 'EducationDocumentSearchTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false,
    availableHearingLocations: [],
    latestInformalHearingPresentationTask: {},
    canMoveOnDocketSwitch: true,
    timerEndsAt: null,
    unscheduledHearingNotes: {}
  }
};

const preDocketTaskData = {
  7123: {
    uniqueId: '7123',
    isLegacy: false,
    type: 'PreDocketTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1634,
    externalAppealId: '06daf6cb-f638-4d13-8c9a-5dbe7feab70f',
    assignedOn: '2022-09-09T09:41:17.554-04:00',
    closestRegionalOffice: null,
    createdAt: '2022-09-08T14:16:50.774-04:00',
    closedAt: null,
    startedAt: null,
    assigneeName: 'BVA Intake',
    assignedTo: {
      cssId: null,
      name: 'BVA Intake',
      id: 4,
      isOrganization: true,
      type: 'BvaIntake'
    },
    assignedBy: {
      firstName: 'Deborah',
      lastName: 'Wise',
      cssId: 'BVADWISE',
      pgId: 17
    },
    cancelledBy: {
      cssId: null
    },
    cancelReason: null,
    convertedBy: {
      cssId: null
    },
    convertedOn: null,
    taskId: '7123',
    parentId: 7122,
    label: 'Pre-Docket',
    documentId: null,
    externalHearingId: null,
    workProduct: null,
    previousTaskAssignedOn: null,
    placedOnHoldAt: '2022-09-08T14:16:50.819-04:00',
    status: 'assigned',
    onHoldDuration: null,
    instructions: [],
    decisionPreparedBy: null,
    availableActions: [
      {
        func: 'docket_appeal_data',
        label: 'Docket appeal',
        value: 'modal/docket_appeal',
        data: {
          modal_title: 'Docket appeal',
          modal_body: 'Please confirm that the documents provided by VHA are available in VBMS before docketing this appeal.',
          modal_alert: 'Once you confirm, the appeal will be established. Please remember to send the docketing letter out to all parties and representatives.',
          instructions_label: 'Provide instructions and context for this action:',
          redirect_after: '/organizations/bva-intake'
        }
      },
      {
        func: 'bva_intake_return_to_camo',
        label: 'Return appeal to VHA',
        value: 'modal/bva_intake_return_to_camo',
        data: {
          selected: {
            id: 31,
            accepts_priority_pushed_cases: null,
            ama_only_push: false,
            ama_only_request: false,
            created_at: '2022-09-08T13:29:34.629-04:00',
            name: 'VHA CAMO',
            participant_id: null,
            role: null,
            status: 'active',
            status_updated_at: null,
            updated_at: '2022-09-08T13:29:34.629-04:00',
            url: 'vha-camo'
          },
          options: [
            {
              label: 'VHA CAMO',
              value: 31
            }
          ],
          modal_title: 'Return appeal to VHA',
          modal_body: 'If you are unable to docket this appeal due to insufficient documentation, you may return this to VHA.',
          message_title: 'You have successfully returned Bob Smithhettinger\'s case to VHA',
          type: 'VhaDocumentSearchTask',
          redirect_after: '/organizations/bva-intake'
        }
      },
      {
        func: 'bva_intake_return_to_caregiver',
        label: 'Return appeal to VHA Caregiver Support Program',
        value: 'modal/bva_intake_return_to_caregiver',
        data: {
          selected: {
            id: 32,
            accepts_priority_pushed_cases: null,
            ama_only_push: false,
            ama_only_request: false,
            created_at: '2022-09-08T13:29:34.779-04:00',
            name: 'VHA Caregiver Support Program',
            participant_id: null,
            role: null,
            status: 'active',
            status_updated_at: null,
            updated_at: '2022-09-08T13:29:34.779-04:00',
            url: 'vha-csp'
          },
          options: [
            {
              label: 'VHA Caregiver Support Program',
              value: 32
            }
          ],
          modal_title: 'Return appeal to VHA Caregiver Support Program',
          modal_body: 'If you are unable to docket this appeal due to insufficient documentation, you may return this to VHA Caregiver Support Program.',
          message_title: 'You have successfully returned Bob Smithwuckert\'s case to Caregiver Support Program',
          type: 'VhaDocumentSearchTask',
          redirect_after: '/organizations/bva-intake'
        }
      },
      {
        func: 'bva_intake_return_to_emo',
        label: 'Return appeal to Education Service',
        value: 'modal/bva_intake_return_to_emo',
        data: {
          selected: {
            id: 56,
            accepts_priority_pushed_cases: null,
            ama_only_push: false,
            ama_only_request: false,
            created_at: '2022-09-08T13:31:28.398-04:00',
            name: 'Executive Management Office',
            participant_id: null,
            role: null,
            status: 'active',
            status_updated_at: null,
            updated_at: '2022-09-08T13:31:28.398-04:00',
            url: 'edu-emo'
          },
          options: [
            {
              label: 'Executive Management Office',
              value: 56
            }
          ],
          modal_title: 'Return appeal to Education Service',
          modal_body: 'If you are unable to docket this appeal due to insufficient documentation, you may return this to Education Service.',
          message_title: 'You have successfully returned Bob Smithhettinger\'s case to Education Service',
          type: 'EducationDocumentSearchTask',
          redirect_after: '/organizations/bva-intake'
        }
      }
    ],
    timelineTitle: 'PreDocketTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false,
    availableHearingLocations: [],
    latestInformalHearingPresentationTask: {},
    canMoveOnDocketSwitch: false,
    timerEndsAt: null,
    unscheduledHearingNotes: {}
  },
};

const assessDocumentationTaskData = {
  7159: {
    uniqueId: '7159',
    isLegacy: false,
    type: 'AssessDocumentationTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1641,
    externalAppealId: '629afccf-1eeb-456c-87d6-48aa59a9b1ab',
    assignedOn: '2022-09-14T13:11:07.484-04:00',
    closestRegionalOffice: null,
    createdAt: '2022-09-14T13:11:07.484-04:00',
    closedAt: null,
    startedAt: null,
    assigneeName: 'Prosthetics',
    assignedTo: {
      cssId: null,
      name: 'Prosthetics',
      id: 37,
      isOrganization: true,
      type: 'VhaProgramOffice'
    },
    assignedBy: {
      firstName: 'Greg',
      lastName: 'Camo',
      cssId: 'CAMOUSER',
      pgId: 4201
    },
    cancelledBy: {
      cssId: null
    },
    cancelReason: null,
    convertedBy: {
      cssId: null
    },
    convertedOn: null,
    taskId: '7159',
    parentId: 7148,
    label: 'Assess Documentation',
    documentId: null,
    externalHearingId: null,
    workProduct: null,
    previousTaskAssignedOn: null,
    placedOnHoldAt: null,
    status: 'assigned',
    onHoldDuration: null,
    instructions: [],
    decisionPreparedBy: null,
    availableActions: [
      {
        label: 'Put task on hold',
        value: 'modal/place_timed_hold'
      },
      {
        func: 'vha_complete_data',
        label: 'Ready for Review',
        value: 'modal/ready_for_review',
        data: {
          modal_title: 'Where were documents regarding this appeal stored?',
          instructions: [],
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/prosthetics'
        }
      },
      {
        func: 'vha_assign_to_regional_office_data',
        label: 'Assign to VISN',
        value: 'modal/assign_to_regional_office',
        data: {
          options: [
            {
              label: 'VA New England Healthcare System',
              value: 38
            },
            {
              label: 'New York/New Jersey VA Health Care Network',
              value: 39
            },
            {
              label: 'VA Healthcare',
              value: 40
            },
            {
              label: 'VA Capitol Health Care Network',
              value: 41
            },
            {
              label: 'VA Mid-Atlantic Health Care Network',
              value: 42
            },
            {
              label: 'VA Southeast Network',
              value: 43
            },
            {
              label: 'VA Sunshine Healthcare Network',
              value: 44
            },
            {
              label: 'VA MidSouth Healthcare Network',
              value: 45
            },
            {
              label: 'VA Healthcare System',
              value: 46
            },
            {
              label: 'VA Great Lakes Health Care System',
              value: 47
            },
            {
              label: 'VA Heartland Network',
              value: 48
            },
            {
              label: 'South Central VA Health Care Network',
              value: 49
            },
            {
              label: 'VA Heart of Texas Health Care Network',
              value: 50
            },
            {
              label: 'Rocky Mountain Network',
              value: 51
            },
            {
              label: 'Northwest Network',
              value: 52
            },
            {
              label: 'Sierra Pacific Network',
              value: 53
            },
            {
              label: 'Desert Pacific Healthcare Network',
              value: 54
            },
            {
              label: 'VA Midwest Health Care Network',
              value: 55
            }
          ],
          modal_title: 'Assign to VISN/VA Medical Center',
          modal_body: 'Provide instructions and context for this action:',
          modal_selector_placeholder: 'Select VISN/VA Medical Center',
          instructions: [],
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/prosthetics'
        }
      },
      {
        func: 'vha_program_office_return_to_camo',
        label: 'Return to CAMO team',
        value: 'modal/return_to_camo',
        data: {
          modal_title: 'Return to CAMO team',
          message_title: 'You have successfully returned this appeal to the CAMO team',
          message_detail: 'This appeal will be removed from your Queue and placed in the CAMO team\'s Queue',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/prosthetics'
        }
      },
      {
        func: 'vha_mark_task_in_progress',
        label: 'Mark task in progress',
        value: 'modal/mark_task_in_progress',
        data: {
          modal_title: 'Mark task in progress',
          modal_body: 'Please confirm that you are actively working on collecting documents for this appeal.  Once confirmed, other members of your organization will no longer be able to mark this task in progress.',
          message_title: 'You have successfully marked your task as in progress',
          message_detail: 'This appeal will be visible in the "In Progress" tab of your Queue',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/prosthetics'
        }
      }
    ],
    timelineTitle: 'AssessDocumentationTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false,
    availableHearingLocations: [],
    latestInformalHearingPresentationTask: {},
    canMoveOnDocketSwitch: true,
    timerEndsAt: null,
    unscheduledHearingNotes: {}
  }
};

const educationAssessDocumentationTaskData = {
  7168: {
    uniqueId: '7168',
    isLegacy: false,
    type: 'EducationAssessDocumentationTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1647,
    externalAppealId: 'adfd7d18-f848-4df5-9df2-9ca43c58dd13',
    assignedOn: '2022-08-28T14:11:34.079-04:00',
    closestRegionalOffice: null,
    createdAt: '2022-08-28T14:11:34.079-04:00',
    closedAt: null,
    startedAt: null,
    assigneeName: 'Buffalo RPO',
    assignedTo: {
      cssId: null,
      name: 'Buffalo RPO',
      id: 57,
      isOrganization: true,
      type: 'EducationRpo'
    },
    assignedBy: {
      firstName: 'Paul',
      lastName: 'EMO',
      cssId: 'EMOUSER',
      pgId: 4229
    },
    cancelledBy: {
      cssId: null
    },
    cancelReason: null,
    convertedBy: {
      cssId: null
    },
    convertedOn: null,
    taskId: '7168',
    parentId: 7162,
    label: 'Assess Documentation',
    documentId: null,
    externalHearingId: null,
    workProduct: null,
    previousTaskAssignedOn: null,
    placedOnHoldAt: null,
    status: 'assigned',
    onHoldDuration: null,
    instructions: [
      ''
    ],
    decisionPreparedBy: null,
    availableActions: [
      {
        func: 'education_rpo_return_to_emo',
        label: 'Return to Executive Management Office',
        value: 'modal/rpo_return_to_emo',
        data: {
          modal_title: 'Return to Executive Management Office',
          message_title: 'You have successfully returned Bob Smithlesch\'s case to the Executive Management Office',
          modal_button_text: 'Return',
          type: 'EducationAssessDocumentationTask',
          redirect_after: '/organizations/buffalo-rpo'
        }
      },
      {
        func: 'education_rpo_send_to_board_intake_for_review',
        label: 'Ready for Review',
        value: 'modal/rpo_send_to_board_intake_for_review',
        data: {
          modal_title: 'Ready for Review',
          modal_button_text: 'Send',
          type: 'EducationAssessDocumentationTask',
          body_optional: true,
          redirect_after: '/organizations/buffalo-rpo',
          modal_button_text: 'Send'
        }
      },
      {
        func: 'education_rpo_mark_task_in_progress',
        label: 'Mark task in progress',
        value: 'modal/mark_task_in_progress',
        data: {
          modal_title: 'Mark task in progress',
          modal_body: 'Please confirm that you are actively working on collecting documents for this appeal.  Once confirmed, other members of your organization will no longer be able to mark this task in progress.',
          modal_button_text: 'Mark in progress',
          message_title: 'You have successfully marked your task as in progress',
          message_detail: 'This appeal will be visible in the "In Progress" tab of your Queue',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/buffalo-rpo'
        }
      }
    ],
    timelineTitle: 'EducationAssessDocumentationTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false,
    availableHearingLocations: [],
    latestInformalHearingPresentationTask: {},
    canMoveOnDocketSwitch: true,
    timerEndsAt: null,
    unscheduledHearingNotes: {}
  }
};
/* eslint-enable max-len */

export const camoToBvaIntakeData = {
  queue: {
    amaTasks: {
      ...vhaDocumentSearchTaskData
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36'
      }
    }
  },
  ...uiData
};

export const returnToOrgData = {
  queue: {
    amaTasks: {
      ...preDocketTaskData
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36'
      }
    }
  },
  ...uiData
};

export const vhaPOToCAMOData = {
  queue: {
    amaTasks: {
      ...assessDocumentationTaskData
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36'
      }
    }
  },
  ...uiData
};

export const emoToBvaIntakeData = {
  queue: {
    amaTasks: {
      ...educationDocumentSearchTaskData
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36'
      }
    }
  },
  ...uiData
};

export const rpoToBvaIntakeData = {
  queue: {
    amaTasks: {
      ...educationAssessDocumentationTaskData
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36'
      }
    }
  },
  ...uiData
};

export const caregiverToIntakeData = {
  queue: {
    amaTasks: {
      ...vhaDocumentSearchTaskData,
      [Object.keys(vhaDocumentSearchTaskData)[0]]: {
        ...Object.values(vhaDocumentSearchTaskData)[0],
        availableActions: caregiverActions,
        assigneeName: 'VHA CAREGEVER',
        assignedTo: {
          name: 'VHA CAREGEVER',
          isOrganization: true,
          type: 'VhaCaregiver'
        },
      }
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36'
      }
    }
  },
  ...uiData
};

export const postData = {
  tasks: {
    data: [
      {
        id: '7139',
        type: 'task',
        attributes: {
          assigned_by: {
            first_name: 'Ignacio',
            last_name: 'Shaw',
            full_name: 'Ignacio BvaIntakeUser Shaw',
            css_id: 'BVAISHAW',
            pg_id: 18
          },
          assigned_to: {
            css_id: null,
            full_name: null,
            is_organization: true,
            name: 'VHA CAMO',
            status: 'active',
            type: 'VhaCamo',
            id: 30
          },
          cancelled_by: {
            css_id: null
          },
          converted_by: {
            css_id: null
          },
          previous_task: {
            assigned_at: null
          },
        }
      }
    ],
    alerts: []
  }
};

export const camoToProgramOfficeToCamoData = {
  queue: {
    amaTasks: {
      ...vhaDocumentSearchTaskData,
      7962: {
        uniqueId: '7962',
        isLegacy: false,
        type: 'AssessDocumentationTask',
        appealType: 'Appeal',
        appealId: 1632,
        externalAppealId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
        assigneeName: 'Prosthetics',
        assignedTo: {
          cssId: null,
          name: 'Prosthetics',
          id: 37,
          isOrganization: true,
          type: 'VhaProgramOffice'
        },
        taskId: '7962',
        parentId: 7119,
        label: 'Assess Documentation',
        instructions: [
          'CAMO to PO',
          'Documents for this appeal are stored in VBMS.\n\n**Detail:**\n\n PO back to CAMO!\n'
        ],
        timelineTitle: 'AssessDocumentationTask completed',
      }
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36'
      }
    }
  },
  ...uiData
};
/* eslint-enable max-lines */
