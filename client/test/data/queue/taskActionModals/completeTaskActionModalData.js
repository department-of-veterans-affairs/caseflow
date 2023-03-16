const uiData = {
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
    featureToggles: {}
  }
};

/* eslint-disable max-len */
const caregiverActions = [
  {
    func: 'vha_caregiver_support_mark_task_in_progress',
    label: 'Mark task as in progress',
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
/* eslint-enable max-len */

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
          modal_selector_placeholder: 'Select Program Office',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/vha-camo'
        }
      },
      {
        label: 'Documents ready for Board Intake review',
        func: 'vha_documents_ready_for_bva_intake_review',
        value: 'modal/vha_documents_ready_for_bva_intake_review',
        data: {
          modal_title: 'Documents ready for Board Intake review',
          type: 'VhaDocumentSearchTask',
          redirect_after: '/organizations/vha-camo',
          options: [
            {
              label: 'VBMS',
              value: 'vbms'
            },
            {
              label: 'Centralized Mail Portal',
              value: 'centralized mail portal'
            },
            {
              label: 'Other',
              value: 'other'
            },
          ]
        }
      },
      {
        label: 'Return to Board Intake',
        func: 'vha_return_to_board_intake',
        value: 'modal/vha_return_to_board_intake',
        data: {
          modal_title: 'Return to Board Intake',
          type: 'VhaDocumentSearchTask',
          redirect_after: '/organizations/vha-camo',
          options: [
            {
              label: 'Duplicate',
              value: 'duplicate'
            },
            {
              label: 'HLR Pending',
              value: 'hlr pending'
            },
            {
              label: 'SC Pending',
              value: 'sc pending'
            },
            {
              label: 'Not VHA related',
              value: 'not vha related'
            },
            {
              label: 'Clarification needed from appellant',
              value: 'clarification needed from appellant'
            },
            {
              label: 'No VHA decision',
              value: 'no vha decision'
            },
            {
              label: 'Other',
              value: 'other'
            }
          ]
        }
      },
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

const EducationAssessDocumentationTaskData = {
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
          type: 'EducationAssessDocumentationTask',
          redirect_after: '/organizations/buffalo-rpo',
          modal_button_text: 'Return'
        }
      },
      {
        func: 'education_rpo_send_to_board_intake_for_review',
        label: 'Ready for Review',
        value: 'modal/rpo_send_to_board_intake_for_review',
        data: {
          modal_title: 'Ready for Review',
          type: 'EducationAssessDocumentationTask',
          body_optional: true,
          redirect_after: '/organizations/buffalo-rpo'
        }
      },
      {
        func: 'education_rpo_mark_task_in_progress',
        label: 'Mark task in progress',
        value: 'modal/mark_task_in_progress',
        data: {
          modal_title: 'Mark task in progress',
          modal_body: 'Please confirm that you are actively working on collecting documents for this appeal.  Once confirmed, other members of your organization will no longer be able to mark this task in progress.',
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
      ...EducationAssessDocumentationTaskData
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
