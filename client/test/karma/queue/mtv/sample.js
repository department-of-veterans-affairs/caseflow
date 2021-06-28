/* eslint-disable */
export const tasks = [
  {
    uniqueId: '2',
    isLegacy: false,
    type: 'VacateMotionMailTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1,
    externalAppealId: 'b519f92c-715e-450c-9530-3cb421d61abc',
    assignedOn: '2019-08-09T18:23:32.835-04:00',
    closestRegionalOffice: null,
    createdAt: '2019-09-09T18:23:32.918-04:00',
    closedAt: null,
    assigneeName: 'CSS_ID3',
    assignedTo: {
      cssId: 'CSS_ID3',
      name: 'Case storage',
      id: 6,
      isOrganization: false,
      type: 'User'
    },
    assignedBy: {
      firstName: 'Lauren',
      lastName: 'Roth',
      cssId: 'CSS_ID4',
      pgId: 7
    },
    taskId: '2',
    label: 'Motion to vacate',
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
        label: 'Change task type',
        value: 'modal/change_task_type',
        func: 'change_task_type_data',
        data: {
          options: [
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
              value: 'VacateMotionMailTask',
              label: 'Motion to vacate'
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
        label: 'Assign to team',
        value: 'modal/assign_to_team',
        func: 'assign_to_organization_data',
        data: {
          selected: null,
          options: [
            {
              label: 'Litigation Support',
              value: 1
            },
            {
              label: 'Mail',
              value: 2
            },
            {
              label: 'AOD',
              value: 4
            },
            {
              label: 'Case Review',
              value: 5
            }
          ],
          type: 'Task'
        }
      },
      {
        label: 'Re-assign to person',
        value: 'modal/reassign_to_person',
        func: 'assign_to_user_data',
        data: {
          selected: {
            id: 6,
            created_at: '2019-09-09T18:23:32.578-04:00',
            css_id: 'CSS_ID3',
            efolder_documents_fetched_at: null,
            email: null,
            full_name: 'Motions attorney',
            last_login_at: null,
            roles: [],
            selected_regional_office: null,
            station_id: '101',
            status: 'active',
            status_updated_at: null,
            updated_at: '2019-09-09T18:23:32.578-04:00',
            display_name: 'CSS_ID3 (VACO)'
          },
          options: [],
          type: 'VacateMotionMailTask'
        }
      },
      {
        label: 'Put task on hold',
        value: 'modal/place_timed_hold'
      },
      {
        label: 'Mark task complete',
        value: 'modal/mark_task_complete',
        func: 'complete_data',
        data: {
          modal_body: 'You can find this case in the completed tab of your queue.'
        }
      },
      {
        label: 'Cancel task',
        value: 'modal/cancel_task',
        func: 'cancel_task_data',
        data: {
          modal_title: 'Cancel task',
          modal_body: 'Cancelling this task will return it to the assigner',
          message_title: "Task for Bob Smith's case has been cancelled",
          message_detail: "If you've made a mistake, please email Lauren Roth to manage any changes."
        }
      },
      {
        label: 'Notify Litigation Support of Possible Conflict of Jurisdiction',
        value: 'modal/flag_conflict_of_jurisdiction',
        func: 'flag_conflict_of_jurisdiction_data',
        data: {
          selected: {
            id: 6,
            name: 'Pulac-Cerullo',
            participant_id: null,
            role: null,
            url: 'pulac-cerullo'
          },
          options: [
            {
              label: 'Pulac-Cerullo',
              value: 6
            }
          ],
          type: 'PulacCerulloTask'
        }
      },
      {
        label: 'Send to judge',
        value: 'send_to_judge',
        func: 'send_motion_to_vacate_to_judge_data',
        data: {
          selected: null,
          options: [
            {
              label: 'Judge the Third',
              value: 3
            },
            {
              label: 'Judge the First',
              value: 1
            },
            {
              label: 'Judge the Second',
              value: 2
            }
          ],
          type: 'VacateMotionMailTask'
        }
      }
    ],
    timelineTitle: 'VacateMotionMailTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: false,
    hideFromCaseTimeline: false
  },
  {
    uniqueId: '3',
    isLegacy: false,
    type: 'RootTask',
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 1,
    externalAppealId: 'b519f92c-715e-450c-9530-3cb421d61abc',
    assignedOn: '2019-09-09T18:23:39.454-04:00',
    closestRegionalOffice: null,
    createdAt: '2019-09-09T18:23:39.454-04:00',
    closedAt: null,
    assigneeName: "Board of Veterans' Appeals",
    assignedTo: {
      cssId: null,
      name: 'Case storage',
      id: 3,
      isOrganization: true,
      type: 'Bva'
    },
    assignedBy: {
      firstName: '',
      lastName: '',
      cssId: null,
      pgId: null
    },
    taskId: '3',
    label: 'Root Task',
    documentId: null,
    externalHearingId: null,
    workProduct: null,
    previousTaskAssignedOn: null,
    placedOnHoldAt: null,
    status: 'assigned',
    onHoldDuration: null,
    instructions: [],
    decisionPreparedBy: null,
    availableActions: [],
    timelineTitle: 'RootTask completed',
    hideFromQueueTableView: false,
    hideFromTaskSnapshot: true,
    hideFromCaseTimeline: true
  }
];

export const appeals = [
  {
    hearings: [],
    completedHearingOnPreviousAppeal: false,
    issues: [],
    decisionIssues: [],
    canEditRequestIssues: false,
    appellantFullName: 'Tom Brady',
    appellantAddress: {
      address_line_1: '9999 MISSION ST',
      address_line_2: 'UBER',
      address_line_3: 'APT 2',
      city: 'SAN FRANCISCO',
      country: 'USA',
      state: 'CA',
      zip: '94103'
    },
    appellantRelationship: 'Spouse',
    assignedToLocation: 'Case storage',
    closestRegionalOffice: null,
    availableHearingLocations: [],
    externalId: 'b519f92c-715e-450c-9530-3cb421d61abc',
    decisionDate: null,
    nodDate: '2019-09-08',
    certificationDate: null,
    powerOfAttorney: {
      representative_type: 'Attorney',
      representative_name: 'Clarence Darrow',
      representative_address: {
        address_line_1: '9999 MISSION ST',
        address_line_2: 'UBER',
        address_line_3: 'APT 2',
        city: 'SAN FRANCISCO',
        country: 'USA',
        state: 'CA',
        zip: '94103'
      }
    },
    regionalOffice: null,
    caseflowVeteranId: 1,
    documentID: null,
    caseReviewId: null,
    canEditDocumentId: false,
    attorneyCaseRewriteDetails: {
      overtime: null,
      note_from_attorney: null,
      untimely_evidence: null
    },
    veteranInfo: {
      veteran: {
        full_name: 'Bob Smith',
        gender: 'M',
        date_of_birth: '01/10/1935',
        date_of_death: null,
        email_address: 'Bob.Smith@test.com',
        address: {
          address_line_1: '1234 Main Street',
          address_line_2: null,
          address_line_3: null,
          city: 'Orlando',
          state: 'FL',
          zip: '12345',
          country: 'USA'
        }
      }
    }
  }
];

export const attorneys = [
  { css_id: null, is_organization: true, name: 'LIT_SUPPORT_USER', type: 'Bva', id: 3 },
  {
    id: 68,
    created_at: '2019-07-22T14:15:21.843-04:00',
    css_id: 'BVAEERDMAN',
    efolder_documents_fetched_at: null,
    email: null,
    full_name: 'Ezra M Erdman',
    last_login_at: null,
    roles: [],
    selected_regional_office: null,
    station_id: '101',
    updated_at: '2019-07-29T12:44:21.989-04:00',
    display_name: 'BVAEERDMAN (VACO)'
  },
  {
    id: 69,
    created_at: '2019-07-22T14:15:21.862-04:00',
    css_id: 'BVARDUBUQUE',
    efolder_documents_fetched_at: null,
    email: null,
    full_name: 'Reanna C Du Buque',
    last_login_at: null,
    roles: [],
    selected_regional_office: null,
    station_id: '101',
    updated_at: '2019-07-29T12:44:22.000-04:00',
    display_name: 'BVARDUBUQUE (VACO)'
  },
  {
    id: 70,
    created_at: '2019-07-22T14:15:21.884-04:00',
    css_id: 'BVALSHIELDS',
    efolder_documents_fetched_at: null,
    email: null,
    full_name: 'Lela X Shields',
    last_login_at: null,
    roles: [],
    selected_regional_office: null,
    station_id: '101',
    updated_at: '2019-07-29T12:44:22.012-04:00',
    display_name: 'BVALSHIELDS (VACO)'
  }
];
