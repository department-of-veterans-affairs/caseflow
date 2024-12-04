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

const userOptions = [
  {
    label: 'Theresa BuildHearingSchedule Warner',
    value: 10
  },
  {
    label: 'Felicia BuildAndEditHearingSchedule Orange',
    value: 126
  },
  {
    label: 'Gail Maggio V',
    value: 2000001601
  },
  {
    label: 'Amb. Cherelle Crist',
    value: 2000001881
  },
  {
    label: 'LETITIA SCHUSTER',
    value: 2000014300
  },
  {
    label: 'Manie Bahringer',
    value: 2000000784
  },
  {
    label: 'Young Metz',
    value: 2000001481
  },
  {
    label: 'Tena Green DDS',
    value: 2000001607
  },
  {
    label: 'Horace Paucek',
    value: 2000001608
  },
  {
    label: 'Angelo Harvey',
    value: 2000001752
  },
  {
    label: 'Shu Wilkinson II',
    value: 2000001822
  },
  {
    label: 'Eugene Waelchi JD',
    value: 2000001944
  },
  {
    label: 'Bernadine Lindgren',
    value: 2000002011
  },
  {
    label: 'Lenna Roberts',
    value: 2000002061
  },
  {
    label: 'Dedra Kassulke',
    value: 2000002114
  },
  {
    label: 'Judy Douglas',
    value: 2000002117
  },
  {
    label: 'Yuki Green',
    value: 2000002170
  },
  {
    label: 'Hassan Considine',
    value: 2000002309
  },
  {
    label: 'Cecilia Feeney',
    value: 2000002311
  },
  {
    label: 'Shizue Orn',
    value: 2000002324
  },
  {
    label: 'Marcia Turcotte DDS',
    value: 2000003937
  },
  {
    label: 'Mrs. Roderick Boyle',
    value: 2000008710
  },
  {
    label: 'Rep. Trey Leuschke',
    value: 2000009340
  },
  {
    label: 'Malka Lind MD',
    value: 2000010066
  },
  {
    label: 'Derrick Abernathy',
    value: 2000011140
  },
  {
    label: 'Ramon Bode',
    value: 2000011189
  },
  {
    label: 'Consuelo Rice VM',
    value: 2000011783
  },
  {
    label: 'Robt Reinger',
    value: 2000013679
  },
  {
    label: 'Cruz Kulas',
    value: 2000014113
  },
  {
    label: 'Jeremy Abbott',
    value: 2000014115
  },
  {
    label: 'Lexie Kunze',
    value: 2000014117
  },
  {
    label: 'Jenny Kiehn',
    value: 2000014742
  },
  {
    label: 'Justin Greenholt',
    value: 2000016249
  },
  {
    label: 'Tiffani Heller',
    value: 2000016344
  },
  {
    label: 'Cris Kris',
    value: 2000016552
  },
  {
    label: 'The Hon. Collin Johnston',
    value: 2000016711
  },
  {
    label: 'Susanna Bahringer DDS',
    value: 2000020664
  },
  {
    label: 'Rev. Eric Howell',
    value: 2000021430
  },
  {
    label: 'Anthony Greenfelder',
    value: 2000021431
  },
  {
    label: 'Sen. Bradley Lehner',
    value: 2000021462
  },
  {
    label: 'Arden Boyle',
    value: 2000021472
  },
  {
    label: 'Millard Dach CPA',
    value: 2000021486
  },
  {
    label: 'Phung Reichert DC',
    value: 2000021537
  },
  {
    label: 'Harvey Jenkins',
    value: 2000021577
  },
  {
    label: 'DINO VONRUEDEN',
    value: 2000003482
  },
  {
    label: 'ISREAL D\'AMORE',
    value: 2000003782
  },
  {
    label: 'MAMMIE TREUTEL',
    value: 2000014114
  },
  {
    label: 'Stacy BuildAndEditHearingSchedule Yellow',
    value: 125
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

const hearingPostponementRequestMailTaskData = {
  12570: {
    uniqueId: '12570',
    isLegacy: false,
    type: 'HearingPostponementRequestMailTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1161,
    externalAppealId: '2f316d14-7ae6-4255-8f83-e0489ad5005d',
    assignedOn: '2023-07-28T14:20:26.457-04:00',
    closestRegionalOffice: null,
    createdAt: '2023-07-28T14:20:26.457-04:00',
    closedAt: null,
    startedAt: null,
    assigneeName: 'Hearing Admin',
    assignedTo: {
      cssId: null,
      name: 'Hearing Admin',
      id: 37,
      isOrganization: true,
      type: 'HearingAdmin'
    },
    assignedBy: {
      firstName: 'Huan',
      lastName: 'Tiryaki',
      cssId: 'JOLLY_POSTMAN',
      pgId: 81
    },
    completedBy: {
      cssId: null
    },
    cancelledBy: {
      cssId: null
    },
    cancelReason: null,
    convertedBy: {
      cssId: null
    },
    convertedOn: null,
    taskId: '12570',
    parentId: 12569,
    label: 'Hearing postponement request',
    documentId: null,
    externalHearingId: null,
    workProduct: null,
    caseType: 'Original',
    aod: false,
    previousTaskAssignedOn: null,
    placedOnHoldAt: null,
    status: 'assigned',
    onHoldDuration: null,
    instructions: [
      'test'
    ],
    decisionPreparedBy: null,
    availableActions: [
      {
        label: 'Change task type',
        func: 'change_task_type_data',
        value: 'modal/change_task_type',
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
      },
      {
        label: 'Mark as complete',
        value: 'modal/complete_and_postpone'
      },
      {
        label: 'Assign to team',
        func: 'assign_to_organization_data',
        value: 'modal/assign_to_team',
        data: {
          selected: null,
          options: [
            {
              label: 'Board Dispatch',
              value: 1
            },
            {
              label: 'Case Review',
              value: 2
            },
            {
              label: 'Case Movement Team',
              value: 3
            },
            {
              label: 'BVA Intake',
              value: 4
            },
            {
              label: 'VLJ Support Staff',
              value: 6
            },
            {
              label: 'Transcription',
              value: 7
            },
            {
              label: 'National Cemetery Administration',
              value: 11
            },
            {
              label: 'Translation',
              value: 12
            },
            {
              label: 'Quality Review',
              value: 13
            },
            {
              label: 'AOD',
              value: 14
            },
            {
              label: 'Mail',
              value: 15
            },
            {
              label: 'Privacy Team',
              value: 16
            },
            {
              label: 'Litigation Support',
              value: 17
            },
            {
              label: 'Office of Assessment and Improvement',
              value: 18
            },
            {
              label: 'Office of Chief Counsel',
              value: 19
            },
            {
              label: 'CAVC Litigation Support',
              value: 20
            },
            {
              label: 'Pulac-Cerullo',
              value: 21
            },
            {
              label: 'Hearings Management',
              value: 36
            },
            {
              label: 'VLJ Support Staff',
              value: 2000000023
            },
            {
              label: 'Education',
              value: 2000000219
            },
            {
              label: 'Veterans Readiness and Employment',
              value: 2000000220
            },
            {
              label: 'Loan Guaranty',
              value: 2000000221
            },
            {
              label: 'Veterans Health Administration',
              value: 2000000222
            },
            {
              label: 'Pension & Survivor\'s Benefits',
              value: 2000000590
            },
            {
              label: 'Fiduciary',
              value: 2000000591
            },
            {
              label: 'Compensation',
              value: 2000000592
            },
            {
              label: 'Insurance',
              value: 2000000593
            },
            {
              label: 'Executive Management Office',
              value: 64
            }
          ],
          type: 'HearingPostponementRequestMailTask'
        }
      },
      {
        label: 'Assign to person',
        func: 'assign_to_user_data',
        value: 'modal/assign_to_person',
        data: {
          selected: {
            id: 125,
            last_login_at: '2023-07-31T15:10:08.273-04:00',
            station_id: '101',
            full_name: 'Stacy BuildAndEditHearingSchedule Yellow',
            email: null,
            roles: [
              'Edit HearSched',
              'Build HearSched'
            ],
            created_at: '2023-07-26T08:53:05.164-04:00',
            css_id: 'BVASYELLOW',
            efolder_documents_fetched_at: null,
            selected_regional_office: null,
            status: 'active',
            status_updated_at: null,
            updated_at: '2023-07-31T15:10:08.277-04:00',
            display_name: 'BVASYELLOW (VACO)'
          },
          options: userOptions,
          type: 'HearingPostponementRequestMailTask'
        }
      },
      {
        label: 'Cancel task',
        func: 'cancel_task_data',
        value: 'modal/cancel_task',
        data: {
          modal_title: 'Cancel task',
          message_title: 'Task for Isaiah Davis\'s case has been cancelled',
          message_detail: 'If you have made a mistake, please email Huan MailUser Tiryaki to manage any changes.'
        }
      }
    ],
    timelineTitle: 'HearingPostponementRequestMailTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false,
    availableHearingLocations: [],
    latestInformalHearingPresentationTask: {},
    canMoveOnDocketSwitch: true,
    timerEndsAt: null,
    unscheduledHearingNotes: {},
    ownedBy: 'Hearing Admin',
    daysSinceLastStatusChange: 3,
    daysSinceBoardIntake: 3,
    id: '12570',
    claimant: {},
    appeal_receipt_date: '2023-07-02'
  }
};

export const completeHearingPostponementRequestData = {
  queue: {
    amaTasks: {
      ...hearingPostponementRequestMailTaskData,
    },
    appeals: {
      '2f316d14-7ae6-4255-8f83-e0489ad5005d': {
        id: '1161',
        externalId: '2f316d14-7ae6-4255-8f83-e0489ad5005d',
      },
    },
  },
  ...uiData
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
        externalAppealId: 'adfd7d18-f848-4df5-9df2-9ca43c58dd13',
        veteranParticipantId: '700000093',
        efolderLink: 'https://vefs-claimevidence-ui-uat.stage.bip.va.gov'
      },
    }
  },
  ...uiData,
};

const hearingWithdrawalRequestMailTaskData = {
  12673: {
    uniqueId: '12673',
    isLegacy: false,
    type: 'HearingWithdrawalRequestMailTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1495,
    externalAppealId: '42ad2331-a95c-49dc-8828-0258cfe0ca04',
    assignedOn: '2023-09-19T10:11:11.306-04:00',
    closestRegionalOffice: null,
    createdAt: '2023-09-19T10:11:11.306-04:00',
    closedAt: null,
    startedAt: null,
    assigneeName: 'Hearing Admin',
    assignedTo: {
      cssId: null,
      name: 'Hearing Admin',
      id: 36,
      isOrganization: true,
      type: 'HearingAdmin'
    },
    assignedBy: {
      firstName: 'Huan',
      lastName: 'Tiryaki',
      cssId: 'JOLLY_POSTMAN',
      pgId: 81
    },
    completedBy: {
      cssId: null
    },
    cancelledBy: {
      cssId: null
    },
    cancelReason: null,
    convertedBy: {
      cssId: null
    },
    convertedOn: null,
    taskId: '12673',
    parentId: 12672,
    label: 'Hearing withdrawal request',
    documentId: null,
    externalHearingId: null,
    workProduct: null,
    caseType: 'Original',
    aod: false,
    previousTaskAssignedOn: null,
    placedOnHoldAt: null,
    status: 'assigned',
    onHoldDuration: null,
    instructions: [
      '**LINK TO DOCUMENT:** \n https://vefs-claimevidence-ui-uat.stage.bip.va.gov/file/jsoek249-four-five-nine-jsjei294n4r9 \n\n **DETAILS:** \n TEST'
    ],
    decisionPreparedBy: null,
    availableActions: [
      {
        label: 'Change task type',
        func: 'change_task_type_data',
        value: 'modal/change_task_type',
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
      },
      {
        label: 'Mark as complete and withdraw',
        func: 'withdraw_hearing_data',
        value: 'modal/complete_and_withdraw',
        data: {
          redirect_after: '/queue/appeals/42ad2331-a95c-49dc-8828-0258cfe0ca04',
          modal_title: 'Withdraw hearing',
          modal_body: 'The appeal will be held open for a 90-day evidence submission period before distribution to a judge.',
          message_title: 'You have successfully withdrawn Dusty Schoen\'s hearing request',
          message_detail: 'The appeal will be held open for a 90-day evidence submission period before distribution to a judge.',
          business_payloads: null,
          back_to_hearing_schedule: true
        }
      },
      {
        label: 'Assign to team',
        func: 'assign_to_organization_data',
        value: 'modal/assign_to_team',
        data: {
          selected: null,
          options: [
            {
              label: 'Education',
              value: 2000000219
            },
            {
              label: 'Veterans Readiness and Employment',
              value: 2000000220
            },
            {
              label: 'Loan Guaranty',
              value: 2000000221
            },
            {
              label: 'Veterans Health Administration',
              value: 2000000222
            },
            {
              label: 'Pension & Survivor\'s Benefits',
              value: 2000000590
            },
            {
              label: 'Fiduciary',
              value: 2000000591
            },
            {
              label: 'Compensation',
              value: 2000000592
            },
            {
              label: 'Insurance',
              value: 2000000593
            },
            {
              label: 'National Cemetery Administration',
              value: 2000000011
            },
            {
              label: 'Board Dispatch',
              value: 1
            },
            {
              label: 'Case Review',
              value: 2
            },
            {
              label: 'Case Movement Team',
              value: 3
            },
            {
              label: 'BVA Intake',
              value: 4
            },
            {
              label: 'VLJ Support Staff',
              value: 6
            },
            {
              label: 'Transcription',
              value: 7
            },
            {
              label: 'Translation',
              value: 11
            },
            {
              label: 'Quality Review',
              value: 12
            },
            {
              label: 'AOD',
              value: 13
            },
            {
              label: 'Mail',
              value: 14
            },
            {
              label: 'Privacy Team',
              value: 15
            },
            {
              label: 'Litigation Support',
              value: 16
            },
            {
              label: 'Office of Assessment and Improvement',
              value: 17
            },
            {
              label: 'Office of Chief Counsel',
              value: 18
            },
            {
              label: 'CAVC Litigation Support',
              value: 19
            },
            {
              label: 'Pulac-Cerullo',
              value: 20
            },
            {
              label: 'Hearings Management',
              value: 35
            },
            {
              label: 'VLJ Support Staff',
              value: 2000000023
            },
            {
              label: 'Executive Management Office',
              value: 64
            }
          ],
          type: 'HearingWithdrawalRequestMailTask'
        }
      },
      {
        label: 'Assign to person',
        func: 'assign_to_user_data',
        value: 'modal/assign_to_person',
        data: {
          selected: {
            id: 125,
            last_login_at: '2023-09-19T10:11:16.800-04:00',
            station_id: '101',
            full_name: 'Stacy BuildAndEditHearingSchedule Yellow',
            email: null,
            roles: [
              'Edit HearSched',
              'Build HearSched'
            ],
            created_at: '2023-09-18T21:24:30.918-04:00',
            css_id: 'BVASYELLOW',
            efolder_documents_fetched_at: null,
            selected_regional_office: null,
            status: 'active',
            status_updated_at: null,
            updated_at: '2023-09-19T10:11:16.803-04:00',
            meeting_type: 'pexip',
            display_name: 'BVASYELLOW (VACO)'
          },
          options: userOptions,
          type: 'HearingWithdrawalRequestMailTask'
        }
      },
      {
        label: 'Cancel task',
        func: 'cancel_task_data',
        value: 'modal/cancel_task',
        data: {
          modal_title: 'Cancel task',
          modal_body: 'Cancelling this task will return it to Huan MailUser Tiryaki',
          message_title: 'Task for Dusty Schoen\'s case has been cancelled',
          message_detail: 'If you have made a mistake, please email Huan MailUser Tiryaki to manage any changes.'
        }
      }
    ],
    timelineTitle: 'HearingWithdrawalRequestMailTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false,
    availableHearingLocations: [],
    latestInformalHearingPresentationTask: {},
    canMoveOnDocketSwitch: true,
    timerEndsAt: null,
    unscheduledHearingNotes: {},
    ownedBy: 'Hearing Admin',
    daysSinceLastStatusChange: 0,
    daysSinceBoardIntake: 0,
    id: '12673',
    claimant: {},
    appeal_receipt_date: '2023-04-06'
  }
};

export const UploadTranscriptionVBMSNoErrorData = {
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
    selectedAppealVacolsId: null,
    isRequestingAppealsUsingVeteranId: false,
    selectedAppeal: {},
    receivedAppeals: [],
    search: {
      showErrorMessage: false,
      noAppealsFoundSearchQueryValue: null
    },
    caseSelectCriteria: {
      searchQuery: ''
    },
    assignments: [],
    assignmentsLoaded: false
  },
  queue: {
    judges: {},
    tasks: {},
    amaTasks: {
      7176: {
        uniqueId: '7176',
        isLegacy: false,
        type: 'RootTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1720,
        externalAppealId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        assignedOn: '2024-08-11T13:00:04.369-04:00',
        closestRegionalOffice: null,
        createdAt: '2024-09-10T13:00:04.375-04:00',
        closedAt: null,
        startedAt: null,
        assigneeName: 'Board of Veterans\' Appeals',
        assignedTo: {
          cssId: null,
          name: 'Board of Veterans\' Appeals',
          id: 7,
          isOrganization: true,
          type: 'Bva'
        },
        assignedBy: {
          firstName: '',
          lastName: '',
          cssId: null,
          pgId: null
        },
        completedBy: {
          cssId: null
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '7176',
        parentId: null,
        label: 'Root Task',
        documentId: null,
        externalHearingId: null,
        workProduct: null,
        caseType: 'Original',
        aod: false,
        previousTaskAssignedOn: null,
        placedOnHoldAt: '2024-09-10T13:00:04.421-04:00',
        status: 'on_hold',
        onHoldDuration: null,
        instructions: [],
        decisionPreparedBy: null,
        availableActions: [],
        timelineTitle: 'RootTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: true,
        hideFromCaseTimeline: true,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: false,
        timerEndsAt: null,
        unscheduledHearingNotes: {},
        ownedBy: 'Board of Veterans\' Appeals',
        daysSinceLastStatusChange: 44,
        daysSinceBoardIntake: 44,
        id: '7176',
        claimant: {},
        appeal_receipt_date: '2024-09-09'
      },
      7177: {
        uniqueId: '7177',
        isLegacy: false,
        type: 'DistributionTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1720,
        externalAppealId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        assignedOn: '2024-09-10T13:00:04.804-04:00',
        closestRegionalOffice: null,
        createdAt: '2024-09-10T13:00:04.403-04:00',
        closedAt: null,
        startedAt: null,
        assigneeName: 'Board of Veterans\' Appeals',
        assignedTo: {
          cssId: null,
          name: 'Board of Veterans\' Appeals',
          id: 7,
          isOrganization: true,
          type: 'Bva'
        },
        assignedBy: {
          firstName: '',
          lastName: '',
          cssId: null,
          pgId: null
        },
        completedBy: {
          cssId: null
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '7177',
        parentId: 7176,
        label: 'Distribution Task',
        documentId: null,
        externalHearingId: null,
        workProduct: null,
        caseType: 'Original',
        aod: false,
        previousTaskAssignedOn: null,
        placedOnHoldAt: '2024-09-10T13:00:05.039-04:00',
        status: 'on_hold',
        onHoldDuration: null,
        instructions: [],
        decisionPreparedBy: null,
        availableActions: [],
        timelineTitle: 'DistributionTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: false,
        hideFromCaseTimeline: false,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: false,
        timerEndsAt: null,
        unscheduledHearingNotes: {},
        ownedBy: 'Board of Veterans\' Appeals',
        daysSinceLastStatusChange: 44,
        daysSinceBoardIntake: 44,
        id: '7177',
        claimant: {},
        appeal_receipt_date: '2024-09-09'
      },
      7178: {
        uniqueId: '7178',
        isLegacy: false,
        type: 'HearingWithdrawalRequestMailTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1720,
        externalAppealId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        assignedOn: '2024-08-06T13:00:04.324-04:00',
        closestRegionalOffice: null,
        createdAt: '2024-09-10T13:00:04.496-04:00',
        closedAt: null,
        startedAt: null,
        assigneeName: 'Mail',
        assignedTo: {
          cssId: null,
          name: 'Mail',
          id: 16,
          isOrganization: true,
          type: 'MailTeam'
        },
        assignedBy: {
          firstName: 'Lauren',
          lastName: 'Roth',
          cssId: 'CSSID7604680',
          pgId: 1874
        },
        completedBy: {
          cssId: null
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '7178',
        parentId: 7176,
        label: 'Hearing withdrawal request',
        documentId: null,
        externalHearingId: null,
        workProduct: null,
        caseType: 'Original',
        aod: false,
        previousTaskAssignedOn: null,
        placedOnHoldAt: '2024-09-10T13:00:05.148-04:00',
        status: 'on_hold',
        onHoldDuration: null,
        instructions: [
          '**LINK TO DOCUMENT:** \n https://www.caseflowreader.com/doc \n\n **DETAILS:** \n Context on task creation'
        ],
        decisionPreparedBy: null,
        availableActions: [],
        timelineTitle: 'HearingWithdrawalRequestMailTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: true,
        hideFromCaseTimeline: true,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: false,
        timerEndsAt: null,
        unscheduledHearingNotes: {},
        ownedBy: 'Mail',
        daysSinceLastStatusChange: 44,
        daysSinceBoardIntake: 44,
        id: '7178',
        claimant: {},
        appeal_receipt_date: '2024-09-09'
      },
      7179: {
        uniqueId: '7179',
        isLegacy: false,
        type: 'HearingTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1720,
        externalAppealId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        assignedOn: '2024-09-10T13:00:04.574-04:00',
        closestRegionalOffice: null,
        createdAt: '2024-09-10T13:00:04.574-04:00',
        closedAt: null,
        startedAt: null,
        assigneeName: 'Board of Veterans\' Appeals',
        assignedTo: {
          cssId: null,
          name: 'Board of Veterans\' Appeals',
          id: 7,
          isOrganization: true,
          type: 'Bva'
        },
        assignedBy: {
          firstName: '',
          lastName: '',
          cssId: null,
          pgId: null
        },
        completedBy: {
          cssId: null
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '7179',
        parentId: 7177,
        label: 'All hearing-related tasks',
        documentId: null,
        externalHearingId: '86ba7d80-277e-429b-98e6-55e67ea06f84',
        workProduct: null,
        caseType: 'Original',
        aod: false,
        previousTaskAssignedOn: null,
        placedOnHoldAt: '2024-09-10T13:00:05.104-04:00',
        status: 'on_hold',
        onHoldDuration: null,
        instructions: [
          'This task will be auto-completed when all hearing-related tasks have been completed.'
        ],
        decisionPreparedBy: null,
        availableActions: [],
        timelineTitle: 'HearingTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: false,
        hideFromCaseTimeline: false,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: false,
        timerEndsAt: null,
        unscheduledHearingNotes: {
          updatedAt: null,
          updatedByCssId: null,
          notes: null
        },
        ownedBy: 'Board of Veterans\' Appeals',
        daysSinceLastStatusChange: 44,
        daysSinceBoardIntake: 44,
        id: '7179',
        claimant: {},
        appeal_receipt_date: '2024-09-09'
      },
      7180: {
        uniqueId: '7180',
        isLegacy: false,
        type: 'ScheduleHearingTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1720,
        externalAppealId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        assignedOn: '2024-09-10T13:00:04.544-04:00',
        closestRegionalOffice: null,
        createdAt: '2024-09-10T13:00:04.544-04:00',
        closedAt: '2024-09-10T13:00:04.646-04:00',
        startedAt: null,
        assigneeName: 'Board of Veterans\' Appeals',
        assignedTo: {
          cssId: null,
          name: 'Board of Veterans\' Appeals',
          id: 7,
          isOrganization: true,
          type: 'Bva'
        },
        assignedBy: {
          firstName: '',
          lastName: '',
          cssId: null,
          pgId: null
        },
        completedBy: {
          cssId: null
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '7180',
        parentId: 7179,
        label: 'Schedule hearing',
        documentId: null,
        externalHearingId: '86ba7d80-277e-429b-98e6-55e67ea06f84',
        workProduct: null,
        caseType: 'Original',
        aod: false,
        previousTaskAssignedOn: null,
        placedOnHoldAt: null,
        status: 'completed',
        onHoldDuration: null,
        instructions: [
          'Schedule Veteran and/or appellant for Board hearing.'
        ],
        decisionPreparedBy: null,
        availableActions: [],
        timelineTitle: 'ScheduleHearingTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: false,
        hideFromCaseTimeline: false,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: false,
        timerEndsAt: null,
        unscheduledHearingNotes: {},
        ownedBy: 'Board of Veterans\' Appeals',
        daysSinceLastStatusChange: 44,
        daysSinceBoardIntake: 44,
        id: '7180',
        claimant: {},
        appeal_receipt_date: '2024-09-09'
      },
      7181: {
        uniqueId: '7181',
        isLegacy: false,
        type: 'AssignHearingDispositionTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1720,
        externalAppealId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        assignedOn: '2024-09-10T13:00:05.073-04:00',
        closestRegionalOffice: null,
        createdAt: '2024-09-10T13:00:05.073-04:00',
        closedAt: null,
        startedAt: null,
        assigneeName: 'Board of Veterans\' Appeals',
        assignedTo: {
          cssId: null,
          name: 'Board of Veterans\' Appeals',
          id: 7,
          isOrganization: true,
          type: 'Bva'
        },
        assignedBy: {
          firstName: '',
          lastName: '',
          cssId: null,
          pgId: null
        },
        completedBy: {
          cssId: null
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '7181',
        parentId: 7179,
        label: 'Select hearing disposition',
        documentId: null,
        externalHearingId: '86ba7d80-277e-429b-98e6-55e67ea06f84',
        workProduct: null,
        caseType: 'Original',
        aod: false,
        previousTaskAssignedOn: null,
        placedOnHoldAt: null,
        status: 'assigned',
        onHoldDuration: null,
        instructions: [
          'Postpone or cancel a hearing prior to the hearing date. This task will be auto-completed after the hearing\'s scheduled date.'
        ],
        decisionPreparedBy: null,
        availableActions: [
          {
            func: 'add_schedule_hearing_task_admin_actions_data',
            label: 'Postpone hearing',
            value: 'modal/postpone_hearing',
            data: {
              redirect_after: '/queue/appeals/8025c5b4-76e7-4a56-a760-8a7cbc565e06',
              schedule_hearing_action_path: 'schedule_veteran',
              message_detail: 'The task has been placed in your teams queue.',
              selected: null,
              options: [
                {
                  value: 'HearingAdminActionContestedClaimantTask',
                  label: 'Contested claimant issue'
                },
                {
                  value: 'HearingAdminActionFoiaPrivacyRequestTask',
                  label: 'FOIA/Privacy request'
                },
                {
                  value: 'HearingAdminActionForeignVeteranCaseTask',
                  label: 'Foreign Veteran case'
                },
                {
                  value: 'HearingAdminActionMissingFormsTask',
                  label: 'Missing forms'
                },
                {
                  value: 'HearingAdminActionOtherTask',
                  label: 'Other'
                },
                {
                  value: 'HearingAdminActionVerifyAddressTask',
                  label: 'Verify Address'
                },
                {
                  value: 'HearingAdminActionVerifyPoaTask',
                  label: 'Verify power of attorney'
                },
                {
                  value: 'HearingAdminActionIncarceratedVeteranTask',
                  label: 'Veteran is incarcerated'
                }
              ]
            }
          },
          {
            func: 'withdraw_hearing_data',
            label: 'Withdraw hearing',
            value: 'modal/cancel_task',
            data: {
              redirect_after: '/queue/appeals/8025c5b4-76e7-4a56-a760-8a7cbc565e06',
              modal_title: 'Withdraw hearing',
              modal_body: 'The appeal will be held open for a 90-day evidence submission period before distribution to a judge.',
              message_title: 'You have successfully withdrawn Bob Smithklocko\'s hearing request',
              message_detail: 'The appeal will be held open for a 90-day evidence submission period before distribution to a judge.',
              business_payloads: {
                values: {
                  disposition: 'cancelled'
                }
              },
              back_to_hearing_schedule: false
            }
          },
          {
            label: 'Remove hearing to correct a scheduling error',
            value: 'modal/hearing_scheduled_in_error'
          },
          {
            label: 'Send for hearing disposition change',
            value: 'modal/create_change_hearing_disposition_task'
          }
        ],
        timelineTitle: 'AssignHearingDispositionTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: false,
        hideFromCaseTimeline: false,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: false,
        timerEndsAt: null,
        unscheduledHearingNotes: {},
        ownedBy: 'Board of Veterans\' Appeals',
        daysSinceLastStatusChange: 44,
        daysSinceBoardIntake: 44,
        id: '7181',
        claimant: {},
        appeal_receipt_date: '2024-09-09'
      },
      7182: {
        uniqueId: '7182',
        isLegacy: false,
        type: 'HearingWithdrawalRequestMailTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1720,
        externalAppealId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        assignedOn: '2024-09-10T13:00:05.128-04:00',
        closestRegionalOffice: null,
        createdAt: '2024-09-10T13:00:05.128-04:00',
        closedAt: null,
        startedAt: null,
        assigneeName: 'Hearing Admin',
        assignedTo: {
          cssId: null,
          name: 'Hearing Admin',
          id: 38,
          isOrganization: true,
          type: 'HearingAdmin'
        },
        assignedBy: {
          firstName: '',
          lastName: '',
          cssId: null,
          pgId: null
        },
        completedBy: {
          cssId: null
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '7182',
        parentId: 7178,
        label: 'Hearing withdrawal request',
        documentId: null,
        externalHearingId: null,
        workProduct: null,
        caseType: 'Original',
        aod: false,
        previousTaskAssignedOn: null,
        placedOnHoldAt: null,
        status: 'assigned',
        onHoldDuration: null,
        instructions: [
          '**LINK TO DOCUMENT:** \n https://www.caseflowreader.com/doc \n\n **DETAILS:** \n Context on task creation'
        ],
        decisionPreparedBy: null,
        availableActions: [
          {
            func: 'change_task_type_data',
            label: 'Change task type',
            value: 'modal/change_task_type',
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
          },
          {
            func: 'cancel_task_data',
            label: 'Cancel task',
            value: 'modal/cancel_task',
            data: {
              modal_title: 'Cancel task',
              modal_body: '',
              message_title: 'Task for Bob Smithklocko\'s case has been cancelled',
              message_detail: 'If you have made a mistake, please email the assigner to manage any changes.'
            }
          }
        ],
        timelineTitle: 'HearingWithdrawalRequestMailTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: false,
        hideFromCaseTimeline: false,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: true,
        timerEndsAt: null,
        unscheduledHearingNotes: {},
        ownedBy: 'Hearing Admin',
        daysSinceLastStatusChange: 44,
        daysSinceBoardIntake: 44,
        id: '7182',
        claimant: {},
        appeal_receipt_date: '2024-09-09'
      },
      36370: {
        uniqueId: '36370',
        isLegacy: false,
        type: 'ReviewTranscriptTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1720,
        externalAppealId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        assignedOn: '2024-10-15T13:36:45.429-04:00',
        closestRegionalOffice: null,
        createdAt: '2024-10-15T13:36:45.429-04:00',
        closedAt: null,
        startedAt: null,
        assigneeName: 'Transcription',
        assignedTo: {
          cssId: null,
          name: 'Transcription',
          id: 9,
          isOrganization: true,
          type: 'TranscriptionTeam'
        },
        assignedBy: {
          firstName: '',
          lastName: '',
          cssId: null,
          pgId: null
        },
        completedBy: {
          cssId: null
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '36370',
        parentId: 7176,
        label: 'Review Transcript task',
        documentId: null,
        externalHearingId: null,
        workProduct: null,
        caseType: 'Original',
        aod: false,
        previousTaskAssignedOn: null,
        placedOnHoldAt: null,
        status: 'assigned',
        onHoldDuration: null,
        instructions: 'Review the hearing transcript and upload the final to VBMS once it has been reviewed for errors or corrected.',
        decisionPreparedBy: null,
        availableActions: [],
        timelineTitle: 'ReviewTranscriptTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: false,
        hideFromCaseTimeline: false,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: true,
        timerEndsAt: null,
        unscheduledHearingNotes: {},
        ownedBy: 'Transcription',
        daysSinceLastStatusChange: 9,
        daysSinceBoardIntake: 9,
        id: '36370',
        claimant: {},
        appeal_receipt_date: '2024-09-09'
      },
      36371: {
        uniqueId: '36371',
        isLegacy: false,
        type: 'ReviewTranscriptTask',
        appealType: 'Appeal',
        addedByCssId: null,
        appealId: 1720,
        externalAppealId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        assignedOn: '2024-10-16T13:28:59.487-04:00',
        closestRegionalOffice: null,
        createdAt: '2024-10-16T13:28:59.487-04:00',
        closedAt: null,
        startedAt: '2024-10-24T11:52:57.371-04:00',
        assigneeName: 'BVASORANGE',
        assignedTo: {
          cssId: 'BVASORANGE',
          name: 'BVASORANGE',
          id: 122,
          isOrganization: false,
          type: 'User'
        },
        assignedBy: {
          firstName: '',
          lastName: '',
          cssId: null,
          pgId: null
        },
        completedBy: {
          cssId: null
        },
        cancelledBy: {
          cssId: null
        },
        cancelReason: null,
        convertedBy: {
          cssId: null
        },
        convertedOn: null,
        taskId: '36371',
        parentId: 7176,
        label: 'Review Transcript task',
        documentId: null,
        externalHearingId: null,
        workProduct: null,
        caseType: 'Original',
        aod: false,
        previousTaskAssignedOn: null,
        placedOnHoldAt: null,
        status: 'in_progress',
        onHoldDuration: null,
        instructions: [
          'maite test'
        ],
        decisionPreparedBy: null,
        availableActions: [
          {
            func: 'change_task_type_data',
            label: 'No errors found: Upload transcript to VBMS',
            value: 'modal/upload_transcription_vbms',
            data: {
              redirect_after: '/queue',
              selected: null,
              options: [
                {
                  label: 'IHP',
                  value: 'IhpColocatedTask'
                },
                {
                  label: 'POA clarification',
                  value: 'PoaClarificationColocatedTask'
                },
                {
                  label: 'Hearing clarification',
                  value: 'HearingClarificationColocatedTask'
                },
                {
                  label: 'AOJ',
                  value: 'AojColocatedTask'
                },
                {
                  label: 'Extension',
                  value: 'ExtensionColocatedTask'
                },
                {
                  label: 'Missing hearing transcripts',
                  value: 'MissingHearingTranscriptsColocatedTask'
                },
                {
                  label: 'Unaccredited rep',
                  value: 'UnaccreditedRepColocatedTask'
                },
                {
                  label: 'FOIA',
                  value: 'FoiaColocatedTask'
                },
                {
                  label: 'Retired VLJ',
                  value: 'RetiredVljColocatedTask'
                },
                {
                  label: 'Arneson',
                  value: 'ArnesonColocatedTask'
                },
                {
                  label: 'New rep arguments',
                  value: 'NewRepArgumentsColocatedTask'
                },
                {
                  label: 'Pending scanning (VBMS)',
                  value: 'PendingScanningVbmsColocatedTask'
                },
                {
                  label: 'Address verification',
                  value: 'AddressVerificationColocatedTask'
                },
                {
                  label: 'Confirm schedule hearing',
                  value: 'ScheduleHearingColocatedTask'
                },
                {
                  label: 'Missing records',
                  value: 'MissingRecordsColocatedTask'
                },
                {
                  label: 'Translation',
                  value: 'TranslationColocatedTask'
                },
                {
                  label: 'Stayed appeal',
                  value: 'StayedAppealColocatedTask'
                },
                {
                  label: 'Other',
                  value: 'OtherColocatedTask'
                }
              ]
            }
          },
          {
            label: 'Errors found and corrected: Upload transcript to VBMS'
          },
          {
            label: 'Cancel task'
          }
        ],
        timelineTitle: 'ReviewTranscriptTask completed',
        hideFromQueueTableView: false,
        hideFromTaskSnapshot: false,
        hideFromCaseTimeline: false,
        availableHearingLocations: [],
        latestInformalHearingPresentationTask: {},
        canMoveOnDocketSwitch: true,
        timerEndsAt: null,
        unscheduledHearingNotes: {},
        ownedBy: 'BVASORANGE',
        daysSinceLastStatusChange: 0,
        daysSinceBoardIntake: 8,
        id: '36371',
        claimant: {},
        appeal_receipt_date: '2024-09-09'
      }
    },
    appeals: {
      '8025c5b4-76e7-4a56-a760-8a7cbc565e06': {
        id: '1720',
        appellant_hearing_email_recipient: null,
        representative_hearing_email_recipient: null,
        externalId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        docketName: 'hearing',
        withdrawn: false,
        removed: false,
        overtime: false,
        contestedClaim: true,
        veteranAppellantDeceased: false,
        isLegacyAppeal: false,
        caseType: 'Original',
        isAdvancedOnDocket: false,
        issueCount: 3,
        docketNumber: '240909-1720',
        assignedAttorney: null,
        assignedJudge: null,
        distributedToJudge: false,
        veteranFullName: 'Bob Smithklocko',
        veteranFileNumber: '598752192',
        isPaperCase: false,
        readableHearingRequestType: null,
        readableOriginalHearingRequestType: null,
        vacateType: null,
        cavcRemandsWithDashboard: 0,
        mst: null,
        pact: false,
        hearings: [
          {
            heldBy: null,
            viewedByJudge: false,
            date: '2024-10-10T19:00:00.000-04:00',
            type: 'Virtual',
            externalId: '86ba7d80-277e-429b-98e6-55e67ea06f84',
            disposition: 'held',
            isVirtual: false,
            notes: null,
            createdAt: '2024-09-10T13:00:04.947-04:00'
          }
        ],
        currentUserEmail: null,
        currentUserTimezone: 'America/Los_Angeles',
        completedHearingOnPreviousAppeal: false,
        issues: [
          {
            id: 2292,
            program: 'compensation',
            description: 'Apportionment - nonrating issue description',
            notes: null,
            diagnostic_code: '5008',
            remand_reasons: [],
            closed_status: null,
            decision_date: '2024-07-10',
            mst_status: false,
            pact_status: false,
            mst_justification: null,
            pact_justification: null
          },
          {
            id: 2293,
            program: 'compensation',
            description: 'Apportionment - nonrating issue description',
            notes: null,
            diagnostic_code: '5008',
            remand_reasons: [],
            closed_status: null,
            decision_date: '2024-07-10',
            mst_status: false,
            pact_status: false,
            mst_justification: null,
            pact_justification: null
          },
          {
            id: 2294,
            program: 'compensation',
            description: 'Apportionment - nonrating issue description',
            notes: null,
            diagnostic_code: '5008',
            remand_reasons: [],
            closed_status: null,
            decision_date: '2024-07-10',
            mst_status: false,
            pact_status: false,
            mst_justification: null,
            pact_justification: null
          }
        ],
        decisionIssues: [],
        substituteAppellantClaimantOptions: [
          {
            displayText: 'BOB VANCE, Spouse',
            value: 'CLAIMANT_WITH_PVA_AS_VSO'
          },
          {
            displayText: 'CATHY SMITH, Child',
            value: '1129318238'
          },
          {
            displayText: 'TOM BRADY, Child',
            value: 'no-such-pid'
          }
        ],
        canEditRequestIssues: false,
        unrecognizedAppellantId: null,
        appellantIsNotVeteran: false,
        appellantFullName: 'Tom Brady',
        appellantFirstName: 'Tom',
        appellantMiddleName: 'Edward',
        appellantLastName: 'Brady',
        appellantSuffix: null,
        appellantDateOfBirth: '1998-09-05',
        appellantAddress: {
          address_line_1: '9999 MISSION ST',
          address_line_2: 'UBER',
          address_line_3: 'APT 2',
          city: 'SAN FRANCISCO',
          zip: '94103',
          country: 'USA',
          state: 'CA'
        },
        appellantEmailAddress: 'tom.brady@caseflow.gov',
        appellantPhoneNumber: null,
        appellantType: 'VeteranClaimant',
        appellantPartyType: null,
        appellantTz: 'America/Los_Angeles',
        appellantRelationship: 'Spouse',
        hasPOA: {
          id: 867,
          authzn_change_clmant_addrs_ind: null,
          authzn_poa_access_ind: null,
          claimant_participant_id: '598751541',
          created_at: '2024-09-10T13:00:04.704-04:00',
          file_number: '00001234',
          last_synced_at: '2024-09-10T13:00:04.704-04:00',
          legacy_poa_cd: '100',
          poa_participant_id: '600153863',
          representative_name: 'Clarence Darrow',
          representative_type: 'Attorney',
          updated_at: '2024-09-10T13:00:04.704-04:00'
        },
        assignedToLocation: 'BVASORANGE',
        veteranDateOfDeath: null,
        veteranParticipantId: '598751540',
        closestRegionalOffice: null,
        closestRegionalOfficeLabel: null,
        availableHearingLocations: [],
        efolderLink: 'https://vefs-claimevidence-ui-uat.stage.bip.va.gov',
        status: 'not_distributed',
        decisionDate: null,
        nodDate: '2024-09-09',
        nodDateUpdates: [],
        certificationDate: null,
        powerOfAttorney: {
          representative_type: 'Attorney',
          representative_name: 'Clarence Darrow',
          representative_address: {
            address_line_1: '9999 MISSION ST',
            address_line_2: 'UBER',
            address_line_3: 'APT 2',
            city: 'SAN FRANCISCO',
            zip: '94103',
            country: 'USA',
            state: 'CA'
          },
          representative_email_address: 'jamie.fakerton@caseflowdemo.com',
          representative_tz: 'America/Los_Angeles',
          poa_last_synced_at: '2024-09-10T13:00:04.704-04:00'
        },
        cavcRemand: null,
        regionalOffice: null,
        caseflowVeteranId: 2143,
        documentID: null,
        caseReviewId: null,
        canEditDocumentId: false,
        attorneyCaseRewriteDetails: {
          note_from_attorney: null,
          untimely_evidence: null
        },
        docketSwitch: null,
        switchedDockets: [],
        appellantSubstitution: null,
        substitutions: [],
        hasSameAppealSubstitution: true,
        remandSourceAppealId: null,
        showPostCavcStreamMsg: false,
        remandJudgeName: null,
        hasNotifications: false,
        locationHistory: [],
        hasCompletedSctAssignTask: false,
        veteranInfo: {
          veteran: {
            full_name: 'Bob Smithklocko',
            gender: 'M',
            date_of_birth: '09/10/1994',
            date_of_death: null,
            email_address: 'Bob.Smithklocko@test.com',
            address: {
              address_line_1: '1234 Main Street',
              address_line_2: null,
              address_line_3: null,
              city: 'Orlando',
              state: 'FL',
              zip: '12345',
              country: 'USA'
            },
            relationships: null
          }
        }
      }
    },
    appealDetails: {
      '8025c5b4-76e7-4a56-a760-8a7cbc565e06': {
        hearings: [
          {
            heldBy: null,
            viewedByJudge: false,
            date: '2024-10-10T19:00:00.000-04:00',
            type: 'Virtual',
            externalId: '86ba7d80-277e-429b-98e6-55e67ea06f84',
            disposition: 'held',
            isVirtual: false,
            notes: null,
            createdAt: '2024-09-10T13:00:04.947-04:00'
          }
        ],
        currentUserEmail: null,
        currentUserTimezone: 'America/Los_Angeles',
        completedHearingOnPreviousAppeal: false,
        issues: [
          {
            id: 2292,
            program: 'compensation',
            description: 'Apportionment - nonrating issue description',
            notes: null,
            diagnostic_code: '5008',
            remand_reasons: [],
            closed_status: null,
            decision_date: '2024-07-10',
            mst_status: false,
            pact_status: false,
            mst_justification: null,
            pact_justification: null
          },
          {
            id: 2293,
            program: 'compensation',
            description: 'Apportionment - nonrating issue description',
            notes: null,
            diagnostic_code: '5008',
            remand_reasons: [],
            closed_status: null,
            decision_date: '2024-07-10',
            mst_status: false,
            pact_status: false,
            mst_justification: null,
            pact_justification: null
          },
          {
            id: 2294,
            program: 'compensation',
            description: 'Apportionment - nonrating issue description',
            notes: null,
            diagnostic_code: '5008',
            remand_reasons: [],
            closed_status: null,
            decision_date: '2024-07-10',
            mst_status: false,
            pact_status: false,
            mst_justification: null,
            pact_justification: null
          }
        ],
        decisionIssues: [],
        substituteAppellantClaimantOptions: [
          {
            displayText: 'BOB VANCE, Spouse',
            value: 'CLAIMANT_WITH_PVA_AS_VSO'
          },
          {
            displayText: 'CATHY SMITH, Child',
            value: '1129318238'
          },
          {
            displayText: 'TOM BRADY, Child',
            value: 'no-such-pid'
          }
        ],
        canEditRequestIssues: false,
        unrecognizedAppellantId: null,
        appellantIsNotVeteran: false,
        appellantFullName: 'Tom Brady',
        appellantFirstName: 'Tom',
        appellantMiddleName: 'Edward',
        appellantLastName: 'Brady',
        appellantSuffix: null,
        appellantDateOfBirth: '1998-09-05',
        appellantAddress: {
          address_line_1: '9999 MISSION ST',
          address_line_2: 'UBER',
          address_line_3: 'APT 2',
          city: 'SAN FRANCISCO',
          zip: '94103',
          country: 'USA',
          state: 'CA'
        },
        appellantEmailAddress: 'tom.brady@caseflow.gov',
        appellantPhoneNumber: null,
        appellantType: 'VeteranClaimant',
        appellantPartyType: null,
        appellantTz: 'America/Los_Angeles',
        appellantRelationship: 'Spouse',
        contestedClaim: true,
        hasPOA: {
          id: 867,
          authzn_change_clmant_addrs_ind: null,
          authzn_poa_access_ind: null,
          claimant_participant_id: '598751541',
          created_at: '2024-09-10T13:00:04.704-04:00',
          file_number: '00001234',
          last_synced_at: '2024-09-10T13:00:04.704-04:00',
          legacy_poa_cd: '100',
          poa_participant_id: '600153863',
          representative_name: 'Clarence Darrow',
          representative_type: 'Attorney',
          updated_at: '2024-09-10T13:00:04.704-04:00'
        },
        assignedToLocation: 'BVASORANGE',
        veteranDateOfDeath: null,
        veteranParticipantId: '598751540',
        closestRegionalOffice: null,
        closestRegionalOfficeLabel: null,
        availableHearingLocations: [],
        externalId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
        efolderLink: 'https://vefs-claimevidence-ui-uat.stage.bip.va.gov',
        status: 'not_distributed',
        decisionDate: null,
        nodDate: '2024-09-09',
        nodDateUpdates: [],
        certificationDate: null,
        powerOfAttorney: {
          representative_type: 'Attorney',
          representative_name: 'Clarence Darrow',
          representative_address: {
            address_line_1: '9999 MISSION ST',
            address_line_2: 'UBER',
            address_line_3: 'APT 2',
            city: 'SAN FRANCISCO',
            zip: '94103',
            country: 'USA',
            state: 'CA'
          },
          representative_email_address: 'jamie.fakerton@caseflowdemo.com',
          representative_tz: 'America/Los_Angeles',
          poa_last_synced_at: '2024-09-10T13:00:04.704-04:00'
        },
        cavcRemand: null,
        regionalOffice: null,
        caseflowVeteranId: 2143,
        documentID: null,
        caseReviewId: null,
        canEditDocumentId: false,
        attorneyCaseRewriteDetails: {
          note_from_attorney: null,
          untimely_evidence: null
        },
        docketSwitch: null,
        switchedDockets: [],
        appellantSubstitution: null,
        substitutions: [],
        hasSameAppealSubstitution: true,
        remandSourceAppealId: null,
        showPostCavcStreamMsg: false,
        remandJudgeName: null,
        hasNotifications: false,
        locationHistory: [],
        hasCompletedSctAssignTask: false,
        mst: null,
        pact: false,
        veteranInfo: {
          veteran: {
            full_name: 'Bob Smithklocko',
            gender: 'M',
            date_of_birth: '09/10/1994',
            date_of_death: null,
            email_address: 'Bob.Smithklocko@test.com',
            address: {
              address_line_1: '1234 Main Street',
              address_line_2: null,
              address_line_3: null,
              city: 'Orlando',
              state: 'FL',
              zip: '12345',
              country: 'USA'
            },
            relationships: null
          }
        }
      }
    },
    claimReviews: {},
    editingIssue: {},
    docCountForAppeal: {
      '8025c5b4-76e7-4a56-a760-8a7cbc565e06': {
        docCountText: 0,
        loading: false
      }
    },
    mostRecentlyHeldHearingForAppeal: {},
    newDocsForAppeal: {},
    newDocsForTask: {},
    specialIssues: {},
    stagedChanges: {
      appeals: {
        '8025c5b4-76e7-4a56-a760-8a7cbc565e06': {
          id: '1720',
          appellant_hearing_email_recipient: null,
          representative_hearing_email_recipient: null,
          externalId: '8025c5b4-76e7-4a56-a760-8a7cbc565e06',
          docketName: 'hearing',
          withdrawn: false,
          removed: false,
          overtime: false,
          contestedClaim: true,
          veteranAppellantDeceased: false,
          isLegacyAppeal: false,
          caseType: 'Original',
          isAdvancedOnDocket: false,
          issueCount: 3,
          docketNumber: '240909-1720',
          assignedAttorney: null,
          assignedJudge: null,
          distributedToJudge: false,
          veteranFullName: 'Bob Smithklocko',
          veteranFileNumber: '598752192',
          isPaperCase: false,
          readableHearingRequestType: null,
          readableOriginalHearingRequestType: null,
          vacateType: null,
          cavcRemandsWithDashboard: 0,
          mst: null,
          pact: false,
          hearings: [
            {
              heldBy: null,
              viewedByJudge: false,
              date: '2024-10-10T19:00:00.000-04:00',
              type: 'Virtual',
              externalId: '86ba7d80-277e-429b-98e6-55e67ea06f84',
              disposition: 'held',
              isVirtual: false,
              notes: null,
              createdAt: '2024-09-10T13:00:04.947-04:00'
            }
          ],
          currentUserEmail: null,
          currentUserTimezone: 'America/Los_Angeles',
          completedHearingOnPreviousAppeal: false,
          issues: [
            {
              id: 2292,
              program: 'compensation',
              description: 'Apportionment - nonrating issue description',
              notes: null,
              diagnostic_code: '5008',
              remand_reasons: [],
              closed_status: null,
              decision_date: '2024-07-10',
              mst_status: false,
              pact_status: false,
              mst_justification: null,
              pact_justification: null
            },
            {
              id: 2293,
              program: 'compensation',
              description: 'Apportionment - nonrating issue description',
              notes: null,
              diagnostic_code: '5008',
              remand_reasons: [],
              closed_status: null,
              decision_date: '2024-07-10',
              mst_status: false,
              pact_status: false,
              mst_justification: null,
              pact_justification: null
            },
            {
              id: 2294,
              program: 'compensation',
              description: 'Apportionment - nonrating issue description',
              notes: null,
              diagnostic_code: '5008',
              remand_reasons: [],
              closed_status: null,
              decision_date: '2024-07-10',
              mst_status: false,
              pact_status: false,
              mst_justification: null,
              pact_justification: null
            }
          ],
          decisionIssues: [],
          substituteAppellantClaimantOptions: [
            {
              displayText: 'BOB VANCE, Spouse',
              value: 'CLAIMANT_WITH_PVA_AS_VSO'
            },
            {
              displayText: 'CATHY SMITH, Child',
              value: '1129318238'
            },
            {
              displayText: 'TOM BRADY, Child',
              value: 'no-such-pid'
            }
          ],
          canEditRequestIssues: false,
          unrecognizedAppellantId: null,
          appellantIsNotVeteran: false,
          appellantFullName: 'Tom Brady',
          appellantFirstName: 'Tom',
          appellantMiddleName: 'Edward',
          appellantLastName: 'Brady',
          appellantSuffix: null,
          appellantDateOfBirth: '1998-09-05',
          appellantAddress: {
            address_line_1: '9999 MISSION ST',
            address_line_2: 'UBER',
            address_line_3: 'APT 2',
            city: 'SAN FRANCISCO',
            zip: '94103',
            country: 'USA',
            state: 'CA'
          },
          appellantEmailAddress: 'tom.brady@caseflow.gov',
          appellantPhoneNumber: null,
          appellantType: 'VeteranClaimant',
          appellantPartyType: null,
          appellantTz: 'America/Los_Angeles',
          appellantRelationship: 'Spouse',
          hasPOA: {
            id: 867,
            authzn_change_clmant_addrs_ind: null,
            authzn_poa_access_ind: null,
            claimant_participant_id: '598751541',
            created_at: '2024-09-10T13:00:04.704-04:00',
            file_number: '00001234',
            last_synced_at: '2024-09-10T13:00:04.704-04:00',
            legacy_poa_cd: '100',
            poa_participant_id: '600153863',
            representative_name: 'Clarence Darrow',
            representative_type: 'Attorney',
            updated_at: '2024-09-10T13:00:04.704-04:00'
          },
          assignedToLocation: 'BVASORANGE',
          veteranDateOfDeath: null,
          veteranParticipantId: '598751540',
          closestRegionalOffice: null,
          closestRegionalOfficeLabel: null,
          availableHearingLocations: [],
          efolderLink: 'https://vefs-claimevidence-ui-uat.stage.bip.va.gov',
          status: 'not_distributed',
          decisionDate: null,
          nodDate: '2024-09-09',
          nodDateUpdates: [],
          certificationDate: null,
          powerOfAttorney: {
            representative_type: 'Attorney',
            representative_name: 'Clarence Darrow',
            representative_address: {
              address_line_1: '9999 MISSION ST',
              address_line_2: 'UBER',
              address_line_3: 'APT 2',
              city: 'SAN FRANCISCO',
              zip: '94103',
              country: 'USA',
              state: 'CA'
            },
            representative_email_address: 'jamie.fakerton@caseflowdemo.com',
            representative_tz: 'America/Los_Angeles',
            poa_last_synced_at: '2024-09-10T13:00:04.704-04:00'
          },
          cavcRemand: null,
          regionalOffice: null,
          caseflowVeteranId: 2143,
          documentID: null,
          caseReviewId: null,
          canEditDocumentId: false,
          attorneyCaseRewriteDetails: {
            note_from_attorney: null,
            untimely_evidence: null
          },
          docketSwitch: null,
          switchedDockets: [],
          appellantSubstitution: null,
          substitutions: [],
          hasSameAppealSubstitution: true,
          remandSourceAppealId: null,
          showPostCavcStreamMsg: false,
          remandJudgeName: null,
          hasNotifications: false,
          locationHistory: [],
          hasCompletedSctAssignTask: false,
          veteranInfo: {
            veteran: {
              full_name: 'Bob Smithklocko',
              gender: 'M',
              date_of_birth: '09/10/1994',
              date_of_death: null,
              email_address: 'Bob.Smithklocko@test.com',
              address: {
                address_line_1: '1234 Main Street',
                address_line_2: null,
                address_line_3: null,
                city: 'Orlando',
                state: 'FL',
                zip: '12345',
                country: 'USA'
              },
              relationships: null
            }
          }
        }
      },
      taskDecision: {
        type: '',
        opts: {}
      }
    },
    attorneysOfJudge: [],
    attorneyAppealsLoadingState: {},
    isTaskAssignedToUserSelected: {},
    pendingDistribution: null,
    attorneys: {},
    organizationId: null,
    organizations: [],
    loadingAppealDetail: {
      '8025c5b4-76e7-4a56-a760-8a7cbc565e06': {
        powerOfAttorney: {
          loading: false
        },
        veteranInfo: {
          loading: false
        }
      }
    },
    queueConfig: {}
  },
  teamManagement: {
    data: {
      dvcTeams: [],
      judgeTeams: [],
      vsos: [],
      privateBars: [],
      vhaProgramOffices: [],
      vhaRegionalOffices: [],
      otherOrgs: []
    },
    loading: false,
    statuses: {}
  },
  ui: {
    selectingJudge: false,
    highlightFormItems: false,
    messages: {
      success: null,
      error: null
    },
    saveState: {
      savePending: false,
      saveSuccessful: null
    },
    modals: {},
    featureToggles: {
      collect_video_and_central_emails: true,
      enable_hearing_time_slots: true,
      schedule_veteran_virtual_hearing: true,
      overtime_revamp: true,
      overtime_persistence: true,
      mdr_cavc_remand: true,
      reversal_cavc_remand: true,
      dismissal_cavc_remand: true,
      editNodDate: true,
      fnod_badge: true,
      fnod_banner: true,
      view_nod_date_updates: true,
      poa_button_refresh: true,
      poa_auto_refresh: false,
      poa_auto_ihp_update: true,
      edit_unrecognized_appellant: true,
      edit_unrecognized_appellant_poa: true,
      listed_granted_substitution_before_dismissal: true,
      restrict_poa_visibility: true,
      vha_predocket_workflow: true,
      vha_irregular_appeals: true,
      vso_virtual_opt_in: true,
      das_case_timeliness: true,
      das_case_timeline: true,
      split_appeal_workflow: true,
      cavc_remand_granted_substitute_appellant: true,
      cavc_dashboard_workflow: false,
      mstIdentification: true,
      pactIdentification: true,
      legacyMstPactIdentification: true,
      justificationReason: false,
      cc_appeal_workflow: true,
      metricsBrowserError: true,
      cc_vacatur_visibility: false,
      conference_selection_visibility: true,
      additional_remand_reasons: true,
      acd_cases_tied_to_judges_no_longer_with_board: true,
      admin_case_distribution: true,
      acd_exclude_from_affinity: true,
      disable_ama_eventing: true
    },
    userRole: '',
    userCssId: 'BVASORANGE',
    userInfo: null,
    organizations: [
      {
        name: 'Transcription',
        url: 'transcription'
      },
      {
        name: 'Hearings Management',
        url: 'hearings-management'
      },
      {
        name: 'Hearing Admin',
        url: 'hearing-admin'
      },
      {
        name: 'Transcription Dispatch',
        url: '/hearings/transcription_files'
      }
    ],
    activeOrganization: {
      id: null,
      name: null,
      isVso: false
    },
    userIsVsoEmployee: false,
    userIsCamoEmployee: false,
    userIsSCTCoordinator: false,
    feedbackUrl: '/feedback',
    loadedUserId: 122,
    selectedAssignee: null,
    selectedAssigneeSecondary: null,
    veteranCaseListIsVisible: false,
    canEditAod: false,
    canEditNodDate: false,
    userIsCobAdmin: false,
    canEditCavcRemands: false,
    canEditCavcDashboards: false,
    canViewCavcDashboards: false,
    hearingDay: {
      hearingDate: null,
      regionalOffice: null
    },
    targetUser: {},
    poaAlert: {},
    conferenceProvider: 'pexip',
    canViewOvertimeStatus: false
  },
  components: {
    scheduledHearingsList: [],
    fetchingHearings: false,
    dropdowns: {
      judges: {},
      hearingCoordinators: {},
      regionalOffices: {}
    },
    forms: {},
    alerts: [],
    transitioningAlerts: {},
    scheduledHearing: {
      taskId: null,
      action: null,
      disposition: null,
      externalId: null,
      polling: false,
      notes: null
    }
  },
  docketSwitch: {
    step: 0,
    formData: {
      disposition: null,
      receiptDate: null,
      docketType: null,
      issueIds: [],
      newTasks: []
    }
  },
  mtv: {
    attorneyView: {
      submitting: false,
      error: null
    },
    judgeView: {
      submitting: false,
      error: null
    }
  },
  substituteAppellant: {
    step: 0,
    formData: {
      substitutionDate: null,
      participantId: null,
      closedTaskIds: [],
      openTaskIds: [],
      cancelledTaskIds: []
    },
    relationships: null,
    loadingRelationships: false,
    poa: null
  },
  cavcRemand: {
    step: 0,
    formData: {
      substitutionDate: null,
      participantId: null,
      decisionType: null,
      docketNumber: null,
      judge: null,
      decisionDate: null,
      issueIds: null,
      federalCircuit: null,
      instructions: null,
      judgementDate: null,
      mandateDate: null,
      remandType: null,
      attorney: null,
      remandDatesProvided: null,
      remandAppealId: null,
      isAppellantSubstituted: null,
      reActivateTaskIds: [],
      cancelTaskIds: []
    },
    relationships: null,
    loadingRelationships: false,
    poa: null
  },
  editClaimantReducer: {
    claimant: {}
  },
  cavcDashboard: {
    decision_reasons: [],
    selection_bases: [],
    initial_state: {
      cavc_dashboards: [],
      checked_boxes: {}
    },
    cavc_dashboards: [],
    checked_boxes: {},
    dashboard_issues: [],
    error: {}
  },
  caching: {
    queueTable: {
      cachedResponses: {}
    }
  }
};

export const completeHearingWithdrawalRequestData = {
  queue: {
    amaTasks: {
      ...hearingWithdrawalRequestMailTaskData,
    },
    appeals: {
      '3f33fe39-dbd7-4cb6-b9dd-c0ead25949fe': {
        id: '1563',
        externalId: '3f33fe39-dbd7-4cb6-b9dd-c0ead25949fe',
      },
    },
  },
  ...uiData
};

export const cancelHearingPostponementRequestData = {
  queue: {
    amaTasks: {
      ...hearingPostponementRequestMailTaskData
    },
    appeals: {
      '2f316d14-7ae6-4255-8f83-e0489ad5005d': {
        id: '1161',
        externalId: '2f316d14-7ae6-4255-8f83-e0489ad5005d'
      }
    },
  },
  ...uiData
};

const correspondenceAvailableActionsList = [
  { label: 'Change task type' },
  { label: 'Assign to team' },
  { label: 'Assign to person' },
  { label: 'Mark task complete' },
  { label: 'Cancel task' }
];
const correspondenceTasksCommonData = {
  assignedTo: 'Litigation Support',
  assignedOn: '09/03/2024',
  type: 'Organization',
  availableActions: correspondenceAvailableActionsList,
  status: 'assigned'
};

export const tasksUnrelatedToAnAppeal = [
  {
    label: 'Other motion',
    instructions: ['test OM'],
    ...correspondenceTasksCommonData
  },
  {
    label: 'FOIA request',
    instructions: ['test OM', 'test cavc2'],
    ...correspondenceTasksCommonData
  },
  {
    label: 'Privacy act request',
    instructions: ['test PAR', 'test par2'],
    ...correspondenceTasksCommonData
  },
  {
    label: 'Congressional interest',
    instructions: ['CI'],
    ...correspondenceTasksCommonData
  },
  {
    label: 'Privacy complaint',
    instructions: ['PC'],
    ...correspondenceTasksCommonData
  },
  {
    label: 'Death certificate',
    instructions: ['DC'],
    ...correspondenceTasksCommonData
  },
  {
    label: 'Power of attorney-related',
    instructions: ['PoAR'],
    ...correspondenceTasksCommonData
  },
  {
    label: 'Status inquiry',
    instructions: ['SI'],
    ...correspondenceTasksCommonData
  },
  {
    label: 'CAVC Correspondence',
    instructions: ['CAVC C'],
    ...correspondenceTasksCommonData
  }
];

/* eslint-enable max-lines */
