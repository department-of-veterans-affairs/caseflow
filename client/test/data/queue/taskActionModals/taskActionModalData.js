/* eslint-disable max-lines */
import COPY from '../../../../COPY';
import { initialState } from '../../../../app/reader/CaseSelect/CaseSelectReducer';
export const uiData = {
  ui: {
    highlightFormItems: false,
    messages: {
      success: null,
      error: null,
    },
    saveState: {
      savePending: false,
      saveSuccessful: null,
    },
    featureToggles: {
      vha_irregular_appeals: true,
    },
  },
};

/* eslint-disable max-len */
const caregiverActions = [
  {
    func: 'vha_caregiver_support_mark_task_in_progress',
    label: 'Mark task in progress',
    value: 'modal/mark_task_in_progress',
    data: {
      modal_title: 'Mark task as in progress',
      modal_body:
        'By marking task as in progress, you are confirming that you are actively working on collecting documents for this appeal.\n\nOnce marked, other members of your organization will no longer be able to mark this task as in progress.',
      modal_button_text: 'Mark in progress',
      message_title:
        "You have successfully marked Bob Smithswift's case as in progress",
      type: 'VhaDocumentSearchTask',
      redirect_after:
        '/organizations/vha-csp?tab=caregiver_support_in_progress',
    },
  },
  {
    func: 'vha_caregiver_support_send_to_board_intake_for_review',
    label: 'Documents ready for Board Intake review',
    value: 'modal/vha_caregiver_support_send_to_board_intake_for_review',
    data: {
      modal_title: 'Ready for review',
      modal_button_text: 'Send',
      message_title:
        "You have successfully sent Bob Smithswift's case to Board Intake for Review",
      type: 'VhaDocumentSearchTask',
      redirect_after: '/organizations/vha-csp?tab=caregiver_support_completed',
      body_optional: true,
    },
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
          value: 'Duplicate',
        },
        {
          label: 'HLR Pending',
          value: 'HLR Pending',
        },
        {
          label: 'SC Pending',
          value: 'SC Pending',
        },
        {
          label: 'Not PCAFC related',
          value: 'Not PCAFC related',
        },
        {
          label: 'No PCAFC decisions for this individual',
          value: 'no PCAFC decisions for this individual',
        },
        {
          label: 'No PCAFC decision for identified time period',
          value: 'No PCAFC decision for identified time period',
        },
        {
          label: 'Multiple PCAFC decisions could apply',
          value: 'Multiple PCAFC decisions could apply',
        },
        {
          label: 'Other',
          value: 'other',
        },
      ],
      redirect_after: '/organizations/vha-csp?tab=caregiver_support_completed',
    },
  },
];

const visnInProgressActions = [
  {
    label: 'End hold early',
    value: 'modal/end_hold'
  },
  {
    func: 'vha_regional_office_return_to_program_office',
    label: 'Return to Program Office',
    value: 'modal/return_to_program_office',
    data: {
      modal_title: 'Return to Program Office',
      message_title: 'You have successfully returned this appeal to the Program Office',
      message_detail: 'This appeal will be removed from your Queue and placed in the Program Office\'s Queue',
      modal_button_text: 'Return',
      type: 'AssessDocumentationTask',
      redirect_after: '/organizations/sierra-pacific-network'
    }
  },
  {
    func: 'vha_complete_data',
    label: 'Documents ready for VHA Program Office team review',
    value: 'modal/ready_for_review',
    data: {
      modal_title: 'Ready for review',
      modal_button_text: 'Send',
      radio_field_label: 'This appeal will be sent to VHA Program Office for review.\n\nPlease select where the documents for this appeal were returned',
      instructions: [],
      type: 'AssessDocumentationTask',
      redirect_after: '/organizations/sierra-pacific-network'
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
      modal_button_text: 'Mark in progress',
      type: 'AssessDocumentationTask',
      redirect_after: '/organizations/sierra-pacific-network'
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
      type: 'VhaCamo',
    },
    assignedBy: {
      firstName: 'Ignacio',
      lastName: 'Shaw',
      cssId: 'BVAISHAW',
      pgId: 18,
    },
    cancelledBy: {
      cssId: null,
    },
    cancelReason: null,
    convertedBy: {
      cssId: null,
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
              value: 33,
            },
            {
              label: 'Community Care - Veteran and Family Members Program',
              value: 34,
            },
            {
              label: 'Member Services - Health Eligibility Center',
              value: 35,
            },
            {
              label: 'Member Services - Beneficiary Travel',
              value: 36,
            },
            {
              label: 'Prosthetics',
              value: 37,
            },
          ],
          modal_title: 'Assign to Program Office',
          modal_body: 'Provide instructions and context for this action:',
          modal_button_text: 'Assign',
          modal_selector_placeholder: 'Select Program Office',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/vha-camo',
        },
      },
      {
        label: 'Documents ready for Board Intake review',
        func: 'vha_documents_ready_for_bva_intake_for_review',
        value: 'modal/vha_documents_ready_for_bva_intake_for_review',
        data: {
          modal_title: 'Ready for review',
          modal_button_text: 'Send',
          body_optional: true,
          type: 'VhaDocumentSearchTask',
          redirect_after: '/organizations/vha-camo',
          options: [
            {
              label: 'VBMS',
              value: 'vbms',
            },
            {
              label: 'Centralized Mail Portal',
              value: 'centralized mail portal',
            },
            {
              label: 'Other',
              value: 'other',
            },
          ],
        },
      },
      {
        label: 'Return to Board Intake',
        func: 'vha_return_to_board_intake',
        value: 'modal/vha_return_to_board_intake',
        data: {
          modal_title: 'Return to Board Intake',
          modal_button_text: 'Return',
          type: 'VhaDocumentSearchTask',
          redirect_after: '/organizations/vha-camo',
          options: [
            {
              label: 'Duplicate',
              value: 'duplicate',
            },
            {
              label: 'HLR Pending',
              value: 'hlr pending',
            },
            {
              label: 'SC Pending',
              value: 'sc pending',
            },
            {
              label: 'Not VHA related',
              value: 'not vha related',
            },
            {
              label: 'Clarification needed from appellant',
              value: 'clarification needed from appellant',
            },
            {
              label: 'No VHA decision',
              value: 'no vha decision',
            },
            {
              label: 'Other',
              value: 'other',
            },
          ],
        },
      },
    ],
    timelineTitle: 'VhaDocumentSearchTask completed',
  },
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
      type: 'EducationEmo',
    },
    assignedBy: {
      firstName: 'Deborah',
      lastName: 'Wise',
      cssId: 'BVADWISE',
      pgId: 17,
    },
    cancelledBy: {
      cssId: null,
    },
    cancelReason: null,
    convertedBy: {
      cssId: null,
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
              value: 57,
            },
            {
              label: 'Central Office RPO',
              value: 58,
            },
            {
              label: 'Muskogee RPO',
              value: 59,
            },
          ],
          modal_title: 'Assign to RPO',
          modal_body: 'Provide instructions and context for this action:',
          modal_selector_placeholder: 'Select RPO',
          modal_button_text: 'Assign',
          type: 'EducationAssessDocumentationTask',
          redirect_after: '/organizations/edu-emo',
          body_optional: true,
        },
      },
      {
        func: 'emo_return_to_board_intake',
        label: 'Return to Board Intake',
        value: 'modal/emo_return_to_board_intake',
        data: {
          modal_title: 'Return to Board Intake',
          modal_button_text: 'Return',
          type: 'EducationDocumentSearchTask',
          instructions_label:
            'Provide instructions and context for this action',
          redirect_after: '/organizations/edu-emo',
        },
      },
      {
        func: 'emo_send_to_board_intake_for_review',
        label: 'Ready for Review',
        value: 'modal/emo_send_to_board_intake_for_review',
        data: {
          modal_title: 'Ready for review',
          modal_button_text: 'Send',
          type: 'EducationDocumentSearchTask',
          redirect_after: '/organizations/edu-emo',
          body_optional: true,
        },
      },
    ],
    timelineTitle: 'EducationDocumentSearchTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false,
    availableHearingLocations: [],
    latestInformalHearingPresentationTask: {},
    canMoveOnDocketSwitch: true,
    timerEndsAt: null,
    unscheduledHearingNotes: {},
  },
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
      type: 'BvaIntake',
    },
    assignedBy: {
      firstName: 'Deborah',
      lastName: 'Wise',
      cssId: 'BVADWISE',
      pgId: 17,
    },
    cancelledBy: {
      cssId: null,
    },
    cancelReason: null,
    convertedBy: {
      cssId: null,
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
          modal_body:
            'Please confirm that the documents provided by VHA are available in VBMS before docketing this appeal.',
          modal_alert:
            'Once you confirm, the appeal will be established. Please remember to send the docketing letter out to all parties and representatives.',
          instructions_label:
            'Provide instructions and context for this action:',
          redirect_after: '/organizations/bva-intake',
        },
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
            url: 'vha-camo',
          },
          options: [
            {
              label: 'VHA CAMO',
              value: 31,
            },
          ],
          modal_title: 'Return appeal to VHA',
          modal_button_text: 'Return',
          modal_body:
            'If you are unable to docket this appeal due to insufficient documentation, you may return this to VHA.',
          message_title:
            "You have successfully returned Bob Smithhettinger's case to VHA",
          type: 'VhaDocumentSearchTask',
          redirect_after: '/organizations/bva-intake',
        },
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
            url: 'vha-csp',
          },
          options: [
            {
              label: 'VHA Caregiver Support Program',
              value: 32,
            },
          ],
          modal_title: 'Return appeal to VHA Caregiver Support Program',
          modal_button_text: 'Return',
          modal_body:
            'If you are unable to docket this appeal due to insufficient documentation, you may return this to VHA Caregiver Support Program.',
          message_title:
            "You have successfully returned Bob Smithwuckert's case to Caregiver Support Program",
          type: 'VhaDocumentSearchTask',
          redirect_after: '/organizations/bva-intake',
        },
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
            url: 'edu-emo',
          },
          options: [
            {
              label: 'Executive Management Office',
              value: 56,
            },
          ],
          modal_title: 'Return appeal to Education Service',
          modal_button_text: 'Return',
          modal_body:
            'If you are unable to docket this appeal due to insufficient documentation, you may return this to Education Service.',
          message_title:
            "You have successfully returned Bob Smithhettinger's case to Education Service",
          type: 'EducationDocumentSearchTask',
          redirect_after: '/organizations/bva-intake',
        },
      },
    ],
    timelineTitle: 'PreDocketTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false,
    availableHearingLocations: [],
    latestInformalHearingPresentationTask: {},
    canMoveOnDocketSwitch: false,
    timerEndsAt: null,
    unscheduledHearingNotes: {},
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
      type: 'VhaProgramOffice',
    },
    assignedBy: {
      firstName: 'Greg',
      lastName: 'Camo',
      cssId: 'CAMOUSER',
      pgId: 4201,
    },
    cancelledBy: {
      cssId: null,
    },
    cancelReason: null,
    convertedBy: {
      cssId: null,
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
        value: 'modal/place_timed_hold',
        modal_button_text: 'Put task on hold',
      },
      {
        func: 'vha_complete_data',
        label: 'Ready for Review',
        value: 'modal/ready_for_review',
        data: {
          modal_title: 'Ready for review',
          modal_button_text: 'Send',
          radio_field_label:
            'This appeal will be sent to VHA CAMO for review.\n\nPlease select where the documents for this appeal were returned',
          instructions: [],
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/prosthetics',
        },
      },
      {
        label: 'Assign to VISN',
        func: 'vha_assign_to_regional_office_data',
        value: 'modal/assign_to_regional_office',
        data: {
          options: {
            vamc: [
              {
                label: 'Edith Nourse Rogers Memorial Veterans Hospital',
                value: 0,
              },
              {
                label: 'Manchester VA Medical Center',
                value: 1,
              },
              {
                label: 'Providence VA Medical Center',
                value: 2,
              },
              {
                label: 'VA Boston Healthcare System',
                value: 3,
              },
              {
                label: 'VA Central Western Massachusetts Healthcare System',
                value: 4,
              },
              {
                label: 'VA Connecticut Healthcare System',
                value: 5,
              },
              {
                label: 'VA Maine Healthcare System',
                value: 6,
              },
              {
                label: 'White River Junction VA Medical Center',
                value: 7,
              },
              {
                label: 'Albany Stratton VA Medical Center',
                value: 8,
              },
              {
                label: 'Bronx VA Medical Center',
                value: 9,
              },
              {
                label: 'Northport VA Medical Center',
                value: 10,
              },
              {
                label: 'Syracuse VA Medical Center',
                value: 11,
              },
              {
                label: 'VA Finger Lakes Healthcare System',
                value: 12,
              },
              {
                label: 'VA Hudson Valley Health Care System',
                value: 13,
              },
              {
                label: 'VA New Jersey Health Care System',
                value: 14,
              },
              {
                label: 'VA New York Harbor Healthcare System',
                value: 15,
              },
              {
                label: 'VA Western NY Healthcare system',
                value: 16,
              },
              {
                label: 'Altoona, PA VAMC',
                value: 17,
              },
              {
                label: 'Butler, PA VAMC',
                value: 18,
              },
              {
                label: 'Coatesville, PA VAMC',
                value: 19,
              },
              {
                label: 'Erie, PA VAMC',
                value: 20,
              },
              {
                label: 'Lebanon, PA VAMC',
                value: 21,
              },
              {
                label: 'Pittsburgh, PA VAMC',
                value: 22,
              },
              {
                label: 'Philadelphia, PA VAMC',
                value: 23,
              },
              {
                label: 'Wilkes-Barre, PA VAMC',
                value: 24,
              },
              {
                label: 'Wilmington, DE VAMC',
                value: 25,
              },
              {
                label: 'Baltimore VAMC',
                value: 26,
              },
              {
                label: 'Beckley VAMC',
                value: 27,
              },
              {
                label: 'Huntington VAMC',
                value: 28,
              },
              {
                label:
                  'Loch Raven VA Community Living and Rehabilitation Center',
                value: 29,
              },
              {
                label: 'Louis A. Johnson AMC',
                value: 30,
              },
              {
                label: 'Martinsburg VAMC',
                value: 31,
              },
              {
                label: 'Perry Point VAMC',
                value: 32,
              },
              {
                label: 'Washington DC VAMC',
                value: 33,
              },
              {
                label: 'Asheville VAMC',
                value: 34,
              },
              {
                label: 'Durham VAMC',
                value: 35,
              },
              {
                label: 'Fayetteville VAMC',
                value: 36,
              },
              {
                label: 'Hampton VAMC',
                value: 37,
              },
              {
                label: 'Richmond VAMC',
                value: 38,
              },
              {
                label: 'Salem VAMC',
                value: 39,
              },
              {
                label: 'Salisbury VAMC',
                value: 40,
              },
              {
                label: 'Atlanta VAMC',
                value: 41,
              },
              {
                label: 'Birmingham VAMC',
                value: 42,
              },
              {
                label: 'Central Alabama Health Care System - East',
                value: 43,
              },
              {
                label: 'Central Alabama Health Care System - West',
                value: 44,
              },
              {
                label: 'Charlie Norwood VAMC',
                value: 45,
              },
              {
                label: 'Carl Vinson VAMC',
                value: 46,
              },
              {
                label: 'Tuscaloosa VAMC',
                value: 47,
              },
              {
                label: 'Ralph H. Johnson VAMC',
                value: 48,
              },
              {
                label: 'Jennings Bryan Dorn VAMC',
                value: 49,
              },
              {
                label: 'Bay Pines Health System',
                value: 50,
              },
              {
                label: 'James A. Haley Veterans’ Hospital',
                value: 51,
              },
              {
                label: 'Miami VA Healthcare System',
                value: 52,
              },
              {
                label: 'North Florida/South Georgia Veterans Health System',
                value: 53,
              },
              {
                label: 'Orlando VAMC – Lake Nona',
                value: 54,
              },
              {
                label: 'VA Caribbean Healthcare System',
                value: 55,
              },
              {
                label: 'West Palm Beach VA Healthcare System',
                value: 56,
              },
              {
                label: 'Lexington VAMC',
                value: 57,
              },
              {
                label: 'Memphis VAMC',
                value: 58,
              },
              {
                label: 'Mountain Home VAMC',
                value: 59,
              },
              {
                label: 'Louisville VAMC',
                value: 60,
              },
              {
                label: 'Tennessee Valley Healthcare System',
                value: 61,
              },
              {
                label: 'Aleda E. Lutz VAMC',
                value: 62,
              },
              {
                label: 'Battle Creek VAMC',
                value: 63,
              },
              {
                label: 'Chalmers P. Wylie VA Ambulatory Care Center',
                value: 64,
              },
              {
                label: 'Chillicothe VAMC',
                value: 65,
              },
              {
                label: 'Cincinnati VANC',
                value: 66,
              },
              {
                label: 'Dayton VAMC',
                value: 67,
              },
              {
                label: 'John D. Dingell VAMC',
                value: 68,
              },
              {
                label: 'Louis Stokes Cleveland VAMC',
                value: 69,
              },
              {
                label: 'Richard L. Roudebush VAMC',
                value: 70,
              },
              {
                label: 'VA Ann Arbor Healthcare System',
                value: 71,
              },
              {
                label: 'VA Northern Indiana Healthcare System – Marion Campus',
                value: 72,
              },
              {
                label:
                  'VA Northern Indiana Healthcare System – Fort Wayne Campus',
                value: 73,
              },
              {
                label: 'Jesse Brown VA Medical Center',
                value: 74,
              },
              {
                label: 'Edward Hines Jr. VA Hospital',
                value: 75,
              },
              {
                label: 'Oscar G. Johnson VA Medical Center',
                value: 76,
              },
              {
                label: 'James A. Lovell FHCC',
                value: 77,
              },
              {
                label: 'William S. Middleton Memorial Veterans Hospital',
                value: 78,
              },
              {
                label: 'Tomah VA Medical Center',
                value: 79,
              },
              {
                label: 'Clement J. Zablocki VA Medical Center',
                value: 80,
              },
              {
                label: 'VA Illiana Health Care System',
                value: 81,
              },
              {
                label: 'Louis VA Health Care System',
                value: 82,
              },
              {
                label: 'Kansas City VA Medical Center',
                value: 83,
              },
              {
                label: 'Harry S. Truman Memorial Veterans’ Hospital',
                value: 84,
              },
              {
                label: 'Eastern Kansas Health Care System',
                value: 85,
              },
              {
                label: 'Robert J. Dole VA Medical Center',
                value: 86,
              },
              {
                label: 'Marion VA Medical Center',
                value: 87,
              },
              {
                label: 'John J. Pershing VA Medical Center',
                value: 88,
              },
              {
                label: 'Alexandria VA Health Care System',
                value: 89,
              },
              {
                label: 'Central Arkansas Veterans Healthcare System',
                value: 90,
              },
              {
                label: 'V. (Sonny) Montgomery VA Medical Center',
                value: 91,
              },
              {
                label: 'Gulf Coast Veterans Health Care System',
                value: 92,
              },
              {
                label: 'Michael E. DeBakey VA Medical Center',
                value: 93,
              },
              {
                label: 'Overton Brooks VA Medical Center',
                value: 94,
              },
              {
                label: 'Southeast Louisiana Veterans Health Care System',
                value: 95,
              },
              {
                label: 'Veterans Health Care System of the Ozarks',
                value: 96,
              },
              {
                label: 'Amarillo VA Health Care System',
                value: 97,
              },
              {
                label: 'Central Texas Veteran Health Care System',
                value: 98,
              },
              {
                label: 'El Paso VA Health Care System',
                value: 99,
              },
              {
                label: 'South Texas Veterans Health Care System',
                value: 100,
              },
              {
                label: 'VA North Texas Health Care System',
                value: 101,
              },
              {
                label: 'VA Texas Valley Coastal Bend Health Care System',
                value: 102,
              },
              {
                label: 'West Texas VA Health Care System',
                value: 103,
              },
              {
                label: 'VA Eastern Colorado Health Care System',
                value: 104,
              },
              {
                label: 'VA Eastern Oklahoma Health Care System',
                value: 105,
              },
              {
                label: 'VA Oklahoma City Health Care System',
                value: 106,
              },
              {
                label: 'VA Montana Health Care System',
                value: 107,
              },
              {
                label: 'VA Salt Lake City Health Care System',
                value: 108,
              },
              {
                label: 'Cheyenne VA Medical Center',
                value: 109,
              },
              {
                label: 'VA Western Colorado Health Care System',
                value: 110,
              },
              {
                label: 'Sheridan VA Medical Center',
                value: 111,
              },
              {
                label: 'VA Northwest Network',
                value: 112,
              },
              {
                label: 'Central California Health Care System',
                value: 113,
              },
              {
                label: 'Manila Outpatient Clinic',
                value: 114,
              },
              {
                label: 'Northern California Health Care System',
                value: 115,
              },
              {
                label: 'Pacific Islands Health Care System',
                value: 116,
              },
              {
                label: 'Palo Alto Health Care System',
                value: 117,
              },
              {
                label: 'San Francisco VA Health Care System',
                value: 118,
              },
              {
                label: 'Sierra Nevada Health Care System',
                value: 119,
              },
              {
                label: 'VA Southern Nevada Healthcare System',
                value: 120,
              },
              {
                label: 'VA Greater Los Angeles Health Care System',
                value: 121,
              },
              {
                label: 'VA Loma Linda Healthcare System',
                value: 122,
              },
              {
                label: 'VA Long Beach Healthcare System',
                value: 123,
              },
              {
                label: 'New Mexico VA Health Care System',
                value: 124,
              },
              {
                label: 'Northern Arizona VA Health Care System',
                value: 125,
              },
              {
                label: 'Phoenix VA Health Care System',
                value: 126,
              },
              {
                label: 'VA San Diego Healthcare System',
                value: 127,
              },
              {
                label: 'Southern Arizona VA Health Care System',
                value: 128,
              },
              {
                label: 'Fargo VA Health Care System',
                value: 129,
              },
              {
                label: 'Iowa City VA Health Care System',
                value: 130,
              },
              {
                label: 'Minneapolis VA Health Care System',
                value: 131,
              },
              {
                label: 'VA Nebraska-Western Iowa Health Care System',
                value: 132,
              },
              {
                label: 'Sioux Falls VA Health Care System',
                value: 133,
              },
              {
                label: 'Cloud VA Health Care System',
                value: 134,
              },
              {
                label: 'VA Black Hills Health Care System',
                value: 135,
              },
              {
                label: 'VA Central Iowa Health Care System',
                value: 136,
              },
            ],
            visn: [
              {
                label: 'VISN 1 - VA New England Healthcare System',
                value: 44,
              },
              {
                label: 'VISN 2 - New York/New Jersey VA Health Care Network',
                value: 45,
              },
              {
                label: 'VISN 4 - VA Healthcare',
                value: 46,
              },
              {
                label: 'VISN 5 - VA Capitol Health Care Network',
                value: 47,
              },
              {
                label: 'VISN 6 - VA Mid-Atlantic Health Care Network',
                value: 48,
              },
              {
                label: 'VISN 7 - VA Southeast Network',
                value: 49,
              },
              {
                label: 'VISN 8 - VA Sunshine Healthcare Network',
                value: 50,
              },
              {
                label: 'VISN 9 - VA MidSouth Healthcare Network',
                value: 51,
              },
              {
                label: 'VISN 10 - VA Healthcare System',
                value: 52,
              },
              {
                label: 'VISN 12 - VA Great Lakes Health Care System',
                value: 53,
              },
              {
                label: 'VISN 15 - VA Heartland Network',
                value: 54,
              },
              {
                label: 'VISN 16 - South Central VA Health Care Network',
                value: 55,
              },
              {
                label: 'VISN 17 - VA Heart of Texas Health Care Network',
                value: 56,
              },
              {
                label: 'VISN 19 - Rocky Mountain Network',
                value: 57,
              },
              {
                label: 'VISN 20 - Northwest Network',
                value: 58,
              },
              {
                label: 'VISN 21 - Sierra Pacific Network',
                value: 59,
              },
              {
                label: 'VISN 22 - Desert Pacific Healthcare Network',
                value: 60,
              },
              {
                label: 'VISN 23 - VA Midwest Health Care Network',
                value: 61,
              },
            ],
          },
          modal_title: 'Assign to VAMC/VISN',
          modal_button_text: 'Assign',
          modal_selector_placeholder: 'Select VISN/VA Medical Center',
          body_optional: true,
          instructions: [],
          instructions_label: 'Provide additional context for this action',
          drop_down_label: {
            vamc: 'VA Medical Center',
            visn: 'VISN',
          },
          type: 'AssessDocumentationTask',
          redirect_after:
            '/organizations/community-care-payment-operations-management',
        },
      },
      {
        func: 'vha_program_office_return_to_camo',
        label: 'Return to CAMO team',
        value: 'modal/return_to_camo',
        data: {
          modal_title: 'Return to CAMO team',
          instructions_label: COPY.VHA_CANCEL_TASK_INSTRUCTIONS_LABEL,
          message_title:
            'You have successfully returned this appeal to the CAMO team',
          modal_button_text: 'Return',
          message_detail:
            "This appeal will be removed from your Queue and placed in the CAMO team's Queue",
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/prosthetics',
        },
      },
      {
        func: 'vha_mark_task_in_progress',
        label: 'Mark task in progress',
        value: 'modal/mark_task_in_progress',
        data: {
          modal_title: 'Mark task in progress',
          modal_body:
            'Please confirm that you are actively working on collecting documents for this appeal.  Once confirmed, other members of your organization will no longer be able to mark this task in progress.',
          message_title:
            'You have successfully marked your task as in progress',
          message_detail:
            'This appeal will be visible in the "In Progress" tab of your Queue',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/prosthetics',
        },
      },
      {
        func: 'vha_regional_office_return_to_program_office',
        label: 'Return to Program Office',
        value: 'modal/return_to_program_office',
        data: {
          modal_title: 'Return to Program Office',
          instructions_label: COPY.VHA_CANCEL_TASK_INSTRUCTIONS_LABEL,
          message_title:
            'You have successfully returned this appeal to the Program Office',
          message_detail:
            "This appeal will be removed from your Queue and placed in the Program Office's Queue",
          modal_button_text: 'Return',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/sierra-pacific-network?tab=po_assigned&page=1"',
        }
      },
    ],
    timelineTitle: 'AssessDocumentationTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false,
    availableHearingLocations: [],
    latestInformalHearingPresentationTask: {},
    canMoveOnDocketSwitch: true,
    timerEndsAt: null,
    unscheduledHearingNotes: {},
  },
};

const assessVISNData = {
  7217: {
    uniqueId: '7217',
    isLegacy: false,
    type: 'AssessDocumentationTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1657,
    externalAppealId: 'b41145a6-6c8b-4e02-a4d9-0963ae61c15a',
    assignedOn: '2022-09-23T15:55:28.334-04:00',
    closestRegionalOffice: null,
    createdAt: '2022-09-23T15:55:28.334-04:00',
    closedAt: null,
    startedAt: null,
    assigneeName: 'Sierra Pacific Network',
    assignedTo: {
      cssId: null,
      name: 'Sierra Pacific Network',
      id: 53,
      isOrganization: true,
      type: 'VhaRegionalOffice',
    },
    assignedBy: {
      firstName: 'Channing',
      lastName: 'Katz',
      cssId: 'VHAPOADMIN',
      pgId: 4206,
    },
    cancelledBy: {
      cssId: null,
    },
    cancelReason: null,
    convertedBy: {
      cssId: null,
    },
    convertedOn: null,
    taskId: '7217',
    parentId: 7216,
    label: 'Assess Documentation',
    documentId: null,
    externalHearingId: null,
    workProduct: null,
    previousTaskAssignedOn: null,
    placedOnHoldAt: null,
    status: 'assigned',
    onHoldDuration: null,
    instructions: ['Assign to Sierra Pacific'],
    decisionPreparedBy: null,
    availableActions: [
      {
        label: 'Put task on hold',
        value: 'modal/place_timed_hold',
      },
      {
        func: 'vha_regional_office_return_to_program_office',
        label: 'Return to Program Office',
        value: 'modal/return_to_program_office',
        data: {
          modal_title: 'Return to Program Office',
          instructions_label: COPY.VHA_CANCEL_TASK_INSTRUCTIONS_LABEL,
          message_title:
            'You have successfully returned this appeal to the Program Office',
          message_detail:
            "This appeal will be removed from your Queue and placed in the Program Office's Queue",
          modal_button_text: 'Return',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/sierra-pacific-network?tab=po_assigned&page=1"',
        },
      },
      {
        func: 'vha_complete_data',
        label: 'Documents ready for VHA Program Office team review',
        value: 'modal/ready_for_review',
        data: {
          modal_title: 'Ready for review',
          modal_button_text: 'Send',
          radio_field_label:
            'This appeal will be sent to VHA Program Office for review.\n\nPlease select where the documents for this appeal were returned',
          instructions: [],
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/sierra-pacific-network',
        },
      },
      {
        func: 'vha_mark_task_in_progress',
        label: 'Mark task in progress',
        value: 'modal/mark_task_in_progress',
        data: {
          modal_title: 'Mark task in progress',
          modal_body:
            'Please confirm that you are actively working on collecting documents for this appeal.  Once confirmed, other members of your organization will no longer be able to mark this task in progress.',
          message_title:
            'You have successfully marked your task as in progress',
          message_detail:
            'This appeal will be visible in the "In Progress" tab of your Queue',
          modal_button_text: 'Mark in progress',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/sierra-pacific-network',
        },
      },
    ],
  },
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
      type: 'EducationRpo',
    },
    assignedBy: {
      firstName: 'Paul',
      lastName: 'EMO',
      cssId: 'EMOUSER',
      pgId: 4229,
    },
    cancelledBy: {
      cssId: null,
    },
    cancelReason: null,
    convertedBy: {
      cssId: null,
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
    instructions: [''],
    decisionPreparedBy: null,
    availableActions: [
      {
        func: 'education_rpo_return_to_emo',
        label: 'Return to Executive Management Office',
        value: 'modal/rpo_return_to_emo',
        data: {
          modal_title: 'Return to Executive Management Office',
          message_title:
            "You have successfully returned Bob Smithlesch's case to the Executive Management Office",
          modal_button_text: 'Return',
          type: 'EducationAssessDocumentationTask',
          redirect_after: '/organizations/buffalo-rpo',
        },
      },
      {
        func: 'education_rpo_send_to_board_intake_for_review',
        label: 'Ready for Review',
        value: 'modal/rpo_send_to_board_intake_for_review',
        data: {
          modal_title: 'Ready for review',
          modal_button_text: 'Send',
          type: 'EducationAssessDocumentationTask',
          body_optional: true,
          redirect_after: '/organizations/buffalo-rpo',
        },
      },
      {
        func: 'education_rpo_mark_task_in_progress',
        label: 'Mark task in progress',
        value: 'modal/mark_task_in_progress',
        data: {
          modal_title: 'Mark task in progress',
          modal_body:
            'Please confirm that you are actively working on collecting documents for this appeal.  Once confirmed, other members of your organization will no longer be able to mark this task in progress.',
          modal_button_text: 'Mark in progress',
          message_title:
            'You have successfully marked your task as in progress',
          message_detail:
            'This appeal will be visible in the "In Progress" tab of your Queue',
          type: 'AssessDocumentationTask',
          redirect_after: '/organizations/buffalo-rpo',
        },
      },
    ],
    timelineTitle: 'EducationAssessDocumentationTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false,
    availableHearingLocations: [],
    latestInformalHearingPresentationTask: {},
    canMoveOnDocketSwitch: true,
    timerEndsAt: null,
    unscheduledHearingNotes: {},
  },
};
/* eslint-enable max-len */

export const camoToBvaIntakeData = {
  queue: {
    amaTasks: {
      ...vhaDocumentSearchTaskData,
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
      },
    },
  },
  ...uiData,
};

export const returnToOrgData = {
  queue: {
    amaTasks: {
      ...preDocketTaskData,
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
      },
    },
  },
  ...uiData,
};

export const visnData = {
  queue: {
    amaTasks: {
      ...assessVISNData,
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
      },
    },
  },
  ...uiData,
};

export const visnOnHoldData = {
  queue: {
    amaTasks: {
      ...assessVISNData,
      [Object.keys(assessVISNData)[0]]: {
        ...Object.values(assessVISNData)[0],
        status: 'on_hold',
        placedOnHoldAt: '2022-09-23T15:55:28.334-04:00',
        availableActions: visnInProgressActions
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

export const vhaPOToCAMOData = {
  queue: {
    amaTasks: {
      ...assessDocumentationTaskData,
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
      },
    },
  },
  ...uiData,
};

export const emoToBvaIntakeData = {
  queue: {
    amaTasks: {
      ...educationDocumentSearchTaskData,
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
      },
    },
  },
  ...uiData,
};

export const rpoToBvaIntakeData = {
  queue: {
    amaTasks: {
      ...educationAssessDocumentationTaskData,
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
      },
    },
  },
  ...uiData,
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
          type: 'VhaCaregiver',
        },
      },
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
      },
    },
  },
  ...uiData,
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
            pg_id: 18,
          },
          assigned_to: {
            css_id: null,
            full_name: null,
            is_organization: true,
            name: 'VHA CAMO',
            status: 'active',
            type: 'VhaCamo',
            id: 30,
          },
          cancelled_by: {
            css_id: null,
          },
          converted_by: {
            css_id: null,
          },
          previous_task: {
            assigned_at: null,
          },
        },
      },
    ],
    alerts: [],
  },
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
          type: 'VhaProgramOffice',
        },
        taskId: '7962',
        parentId: 7119,
        label: 'Assess Documentation',
        instructions: [
          'CAMO to PO',
          '##### STATUS:\nDocuments for this appeal are stored in VBMS.\n\n##### DETAILS:\n PO back to CAMO!\n',
        ],
        timelineTitle: 'AssessDocumentationTask completed',
      },
    },
    appeals: {
      '419ce568-387c-4ac6-a5f5-00a1554cea36': {
        id: '1632',
        externalId: '419ce568-387c-4ac6-a5f5-00a1554cea36',
      },
    },
  },
  ...uiData,
};

export const rootTaskData = {
  caseList: {
    caseListCriteria: {
      searchQuery: ''
    },
    isRequestingAppealsUsingVeteranId: false,
    search: {
      errorType: null,
      queryResultingInError: null,
      errorMessage: null
    },
    fetchedAllCasesFor: {}
  },
  caseSelect: {
    initialState
  },
  queue: {
    judges: {},
    tasks: {},
    amaTasks: {
      7162: {
        uniqueId: '7162',
        isLegacy: false,
        type: 'RootTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1647,
        externalAppealId: 'adfd7d18-f848-4df5-9df2-9ca43c58dd13',
        assignedOn: '2023-06-21T10:15:02.830-04:00',
        closestRegionalOffice: null,
        createdAt: '2023-07-25T10:15:02.836-04:00',
        closedAt: null,
        startedAt: null,
        assigneeName: 'Board of Veterans\' Appeals',
        assignedTo: {
          cssId: null,
          name: 'Board of Veterans\' Appeals',
          id: 5,
          isOrganization: true,
          type: 'Bva'
        },
        assignedBy: {
          firstName: '',
          lastName: '',
          cssId: null,
          pgId: null
        },
        cancelledBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '7162',
        parentId: null,
        label: 'Root Task',
        documentId: null,
        externalHearingId: null,
        workProduct: null,
        placedOnHoldAt: '2023-07-25T10:15:02.851-04:00',
        status: 'on_hold',
        onHoldDuration: null,
        instructions: [],
        decisionPreparedBy: null,
        availableActions: [
          {
            func: 'mail_assign_to_organization_data',
            label: 'Create mail task',
            value: 'modal/create_mail_task',
            data: {
              options: [
                {
                  value: 'CavcCorrespondenceMailTask',
                  label: 'CAVC Correspondence'
                },
                {
                  value: 'ClearAndUnmistakeableErrorMailTask',
                  label: 'CUE-related'
                },
                {
                  value: 'AddressChangeMailTask',
                  label: 'Change of address'
                },
                {
                  value: 'CongressionalInterestMailTask',
                  label: 'Congressional interest'
                },
                {
                  value: 'ControlledCorrespondenceMailTask',
                  label: 'Controlled correspondence'
                },
                {
                  value: 'DeathCertificateMailTask',
                  label: 'Death certificate'
                },
                {
                  value: 'EvidenceOrArgumentMailTask',
                  label: 'Evidence or argument'
                },
                {
                  value: 'ExtensionRequestMailTask',
                  label: 'Extension request'
                },
                {
                  value: 'FoiaRequestMailTask',
                  label: 'FOIA request'
                },
                {
                  value: 'HearingPostponementRequestMailTask',
                  label: 'Hearing postponement request'
                },
                {
                  value: 'HearingRelatedMailTask',
                  label: 'Hearing-related'
                },
                {
                  value: 'ReconsiderationMotionMailTask',
                  label: 'Motion for reconsideration'
                },
                {
                  value: 'AodMotionMailTask',
                  label: 'Motion to Advance on Docket'
                },
                {
                  value: 'OtherMotionMailTask',
                  label: 'Other motion'
                },
                {
                  value: 'PowerOfAttorneyRelatedMailTask',
                  label: 'Power of attorney-related'
                },
                {
                  value: 'PrivacyActRequestMailTask',
                  label: 'Privacy act request'
                },
                {
                  value: 'PrivacyComplaintMailTask',
                  label: 'Privacy complaint'
                },
                {
                  value: 'ReturnedUndeliverableCorrespondenceMailTask',
                  label: 'Returned or undeliverable mail'
                },
                {
                  value: 'StatusInquiryMailTask',
                  label: 'Status inquiry'
                },
                {
                  value: 'AppealWithdrawalMailTask',
                  label: 'Withdrawal of appeal'
                }
              ]
            }
          }
        ],
        timelineTitle: 'RootTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: true,
        hideFromCaseTimeline: true,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: false,
        timerEndsAt: null,
        unscheduledHearingNotes: {}
      }
    },
    appeals: {
      'adfd7d18-f848-4df5-9df2-9ca43c58dd13': {
        id: 1647,
        externalAppealId: 'adfd7d18-f848-4df5-9df2-9ca43c58dd13'
      },
    }
  },
  ...uiData,
};
/* eslint-enable max-lines */
