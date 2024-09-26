export const correspondenceTypes = [
  { id: 1, name: 'Abeyance' },
  { id: 2, name: 'Attorney Inquiry' },
  { id: 3, name: 'CAVE Correspondence' },
  { id: 4, name: 'Change of address' },
  { id: 5, name: 'Congressional interest' },
  { id: 6, name: 'CUE related' },
  { id: 7, name: 'Death certificate' },
  { id: 8, name: 'Evidence or argument' },
  { id: 9, name: 'Extension request' },
  { id: 10, name: 'FOIA request' },
  { id: 11, name: 'Hearing Postponement Request' },
  { id: 12, name: 'Hearing related' },
  { id: 13, name: 'Hearing Withdrawal Request' }
];

export const correspondenceDocumentsData = [
  {
    correspondence_id: 1,
    document_file_number: '998877665',
    pages: 30,
    vbms_document_type_id: 1,
    uuid: null,
    document_type: 1250,
    document_title: 'VA Form 10182 Notice of Disagreement'
  },
  {
    correspondence_id: 2,
    document_file_number: '998877665',
    pages: 20,
    vbms_document_type_id: 1,
    uuid: null,
    document_type: 719,
    document_title: 'Exam Request'
  }
];

export const correspondenceAppeals = [
  {
    id: 50,
    correspondencesAppealsTasks: [],
    docketNumber: '240714-252',
    veteranName: {
      id: 88,
      bgs_last_synced_at: null,
      closest_regional_office: null,
      created_at: '2024-07-15T16:47:17.658-04:00',
      date_of_death: null,
      date_of_death_reported_at: null,
      file_number: '550000017',
      first_name: 'John',
      last_name: 'Doe',
      middle_name: null,
      name_suffix: '88',
      participant_id: '650000017',
      ssn: '252858736',
      updated_at: '2024-07-15T16:47:17.658-04:00'
    },
    streamType: 'original',
    appealUuid: 'b36f1011-a34b-413b-a2b9-90fe0d8b2927',
    appealType: 'evidence_submission',
    numberOfIssues: 2,
    taskAddedData: [],
    status: 'Pending',
    assignedTo: null,
    correspondence: {
      id: 50,
      appeal_id: 252,
      correspondence_id: 322,
      created_at: '2024-08-14T10:53:47.213-04:00',
      updated_at: '2024-08-14T10:53:47.213-04:00'
    },
    appeal: {
      data: {
        attributes: {
          external_id: '2398523958',
          externalId: '2398523958'
        }
      }
    }
  },
  {
    id: 51,
    correspondencesAppealsTasks: [
      {
        id: 27,
        correspondence_appeal_id: 51,
        task_id: 3158,
        created_at: '2024-08-14T10:53:47.616-04:00',
        updated_at: '2024-08-14T10:53:47.616-04:00'
      }
    ],
    docketNumber: '240714-253',
    veteranName: {
      id: 88,
      bgs_last_synced_at: null,
      closest_regional_office: null,
      created_at: '2024-07-15T16:47:17.658-04:00',
      date_of_death: null,
      date_of_death_reported_at: null,
      file_number: '550000017',
      first_name: 'John',
      last_name: 'Doe',
      middle_name: null,
      name_suffix: '88',
      participant_id: '650000017',
      ssn: '252858736',
      updated_at: '2024-07-15T16:47:17.658-04:00'
    },
    streamType: 'original',
    appealUuid: 'a9b2523e-880d-4ef4-9f12-eae9d593631d',
    appealType: 'evidence_submission',
    numberOfIssues: 2,
    taskAddedData: [
      {
        assigned_at: '2024-08-14T10:53:47.560-04:00',
        assigned_to: 'Hearing Admin',
        assigned_to_type: 'Organization',
        instructions: [
          'COA'
        ],
        type: 'Change of address'
      }
    ],
    status: 'Pending',
    assignedTo: {
      id: 39,
      accepts_priority_pushed_cases: null,
      ama_only_push: false,
      ama_only_request: false,
      created_at: '2024-07-15T16:46:00.263-04:00',
      exclude_appeals_from_affinity: false,
      name: 'Hearing Admin',
      participant_id: null,
      role: null,
      status: 'active',
      status_updated_at: null,
      updated_at: '2024-07-15T16:46:00.263-04:00',
      url: 'hearing-admin'
    },
    correspondence: {
      id: 51,
      appeal_id: 253,
      correspondence_id: 322,
      created_at: '2024-08-14T10:53:47.217-04:00',
      updated_at: '2024-08-14T10:53:47.217-04:00'
    },
    appeal: {
      data: {
        attributes: {
          external_id: '2398523958'
        }
      }
    }
  },
  {
    id: 52,
    correspondencesAppealsTasks: [
      {
        id: 1,
        correspondence_appeal_id: 52,
        task_id: 3160,
        created_at: '2024-08-14T10:53:47.678-04:00',
        updated_at: '2024-08-14T10:53:47.678-04:00'
      },
      {
        id: 29,
        correspondence_appeal_id: 52,
        task_id: 3162,
        created_at: '2024-08-14T10:53:47.733-04:00',
        updated_at: '2024-08-14T10:53:47.733-04:00'
      }
    ],
    docketNumber: '240714-254',
    veteranName: {
      id: 88,
      bgs_last_synced_at: null,
      closest_regional_office: null,
      created_at: '2024-07-15T16:47:17.658-04:00',
      date_of_death: null,
      date_of_death_reported_at: null,
      file_number: '550000017',
      first_name: 'John',
      last_name: 'Doe',
      middle_name: null,
      name_suffix: '88',
      participant_id: '650000017',
      ssn: '252858736',
      updated_at: '2024-07-15T16:47:17.658-04:00'
    },
    streamType: 'original',
    appealUuid: '7bd8281d-3b6e-442f-8e44-21b033f7049e',
    appealType: 'evidence_submission',
    numberOfIssues: 2,
    taskAddedData: [
      {
        assigned_at: '2024-08-14T10:53:47.656-04:00',
        assigned_to: 'VLJ Support Staff',
        assigned_to_type: 'Organization',
        instructions: [
          'DC'
        ],
        type: 'Death certificate'
      },
      {
        assigned_at: '2024-08-14T10:53:47.716-04:00',
        assigned_to: 'Litigation Support',
        assigned_to_type: 'Organization',
        instructions: [
          'cong int'
        ],
        type: 'Congressional interest'
      }
    ],
    status: 'Pending',
    assignedTo: {
      id: 8,
      accepts_priority_pushed_cases: null,
      ama_only_push: false,
      ama_only_request: false,
      created_at: '2024-07-15T16:45:56.066-04:00',
      exclude_appeals_from_affinity: false,
      name: 'VLJ Support Staff',
      participant_id: null,
      role: null,
      status: 'active',
      status_updated_at: null,
      updated_at: '2024-07-15T16:45:56.066-04:00',
      url: 'vlj-support'
    },
    correspondence: {
      id: 52,
      appeal_id: 254,
      correspondence_id: 322,
      created_at: '2024-08-14T10:53:47.221-04:00',
      updated_at: '2024-08-14T10:53:47.221-04:00'
    },
    appeal: {
      data: {
        attributes: {
          external_id: '2398523958'
        }
      }
    }
  }
];

export const correspondenceData = {
  id: 1,
  cmp_packet_number: 5555555555,
  cmp_queue_id: 1,
  correspondence_type_id: 8,
  created_at: '2023-11-16 01:44:47.094786',
  notes: 'Some CMP notes here',
  updated_at: '2023-11-16 01:44:47.094786',
  uuid: 'f67702ec-65fb-4b1e-b7c7-d493f7add9e9',
  va_date_of_receipt: '2023-11-15 00:00:00',
  veteran_id: 1928,
  veteranFileNumber: '998877665',
  veteranFullName: 'John Doe',
  correspondenceDocuments: correspondenceDocumentsData,
  correspondence_tasks: [
    {
      id: 1,
      appeal_id: 1,
      appeal_type: 'Correspondence',
      assigned_at: '2024-06-21T10:56:26.035-04:00',
      assigned_by_id: null,
      assigned_to_id: 20,
      assigned_to_type: 'Organization',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: null,
      completed_by_id: null,
      created_at: '2024-06-21T10:56:26.035-04:00',
      instructions: [],
      parent_id: null,
      placed_on_hold_at: '2024-06-21T10:56:26.039-04:00',
      started_at: null,
      status: 'on_hold',
      updated_at: '2024-06-21T10:56:26.039-04:00',
      type: 'CorrespondenceRootTask'
    },
    {
      id: 16769,
      appeal_id: 514,
      appeal_type: 'Correspondence',
      assigned_at: '2024-05-25T11:36:20.007-04:00',
      assigned_by_id: null,
      assigned_to_id: 20,
      assigned_to_type: 'Organization',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: null,
      completed_by_id: null,
      created_at: '2024-06-21T10:56:26.049-04:00',
      instructions: [],
      parent_id: 16768,
      placed_on_hold_at: null,
      started_at: null,
      status: 'unassigned',
      updated_at: '2024-06-21T10:56:26.077-04:00',
      type: 'ReviewPackageTask'
    }
  ]
};

export const correspondenceDetailsData = {
  id: 1,
  cmp_packet_number: 5555555555,
  cmp_queue_id: 1,
  correspondence_type_id: 8,
  created_at: '2023-11-16 01:44:47.094786',
  notes: 'Some CMP notes here',
  mailTasks: ['Task 1', 'Task 2'],
  updated_at: '2023-11-16 01:44:47.094786',
  uuid: 'f67702ec-65fb-4b1e-b7c7-d493f7add9e9',
  va_date_of_receipt: '2023-11-15 00:00:00',
  veteran_id: 1928,
  veteranFileNumber: '998877665',
  veteranFullName: 'John Doe',
  correspondenceDocuments: correspondenceDocumentsData,
  correspondence_tasks: [
    {
      id: 1,
      appeal_id: 1,
      appeal_type: 'Correspondence',
      assigned_at: '2024-06-21T10:56:26.035-04:00',
      assigned_by_id: null,
      assigned_to_id: 20,
      assigned_to_type: 'Organization',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: null,
      completed_by_id: null,
      created_at: '2024-06-21T10:56:26.035-04:00',
      instructions: [],
      parent_id: null,
      placed_on_hold_at: '2024-06-21T10:56:26.039-04:00',
      started_at: null,
      status: 'on_hold',
      updated_at: '2024-06-21T10:56:26.039-04:00',
      type: 'CorrespondenceRootTask'
    },
    {
      id: 2323,
      appeal_id: 513,
      appeal_type: 'Correspondence',
      assigned_at: '2024-05-25T11:36:20.007-04:00',
      assigned_by_id: null,
      assigned_to_id: 20,
      assigned_to_type: 'Organization',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: null,
      completed_by_id: null,
      created_at: '2024-06-21T10:56:26.049-04:00',
      instructions: [],
      parent_id: 16768,
      placed_on_hold_at: null,
      started_at: null,
      status: 'assigned',
      updated_at: '2024-06-21T10:56:26.077-04:00',
      type: 'OtherMotionCorrespondenceTask'
    }
  ]
};

export const appeals = {
  appellantFullName: 'John Doe',
};

export const packageDocumentTypeData = {
  id: 15,
  active: true,
  name: 'NOD',
};

export const correspondence = {
  uuid: '193b4f5e-8868-4ed8-a31d-598b48feadf5',
  id: 555,
  notes: 'This correspondence was originally assigned to and updated by INBOUND_OPS_TEAM_SUPERUSER1.',
  vaDateOfReceipt: '2024-06-16T00:00:00.000-04:00',
  nod: true,
  status: 'Pending',
  type: 'Correspondence',
  veteranId: 101,
  correspondenceDocuments: [
    {
      id: 613,
      correspondence_id: 555,
      document_file_number: '550000030',
      pages: 19,
      vbms_document_type_id: 1250,
      uuid: '7c5e93da-7fe0-4681-888d-f6817e83e221',
      document_type: 1250,
      document_title: 'VA Form 10182 Notice of Disagreement'
    }
  ],
  correspondenceType: 'Abeyance',
  tasksUnrelatedToAppeal: [
    {
      label: 'Privacy act request',
      assignedOn: '09/24/2024',
      assignedTo: 'Privacy Team',
      type: 'Organization',
      instructions: [
        'par'
      ],
      availableActions: [],
      uniqueId: 3208,
      reassignUsers: [
        'PRIVACY_TEAM_USER',
        'RETANBVAJ',
        'GOSNEJVACO',
        'SANFORDBVAM'
      ],
      assignedToOrg: true,
      status: 'assigned',
      organizations: [
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
          label: "Pension & Survivor's Benefits",
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
          value: 8
        },
        {
          label: 'Transcription',
          value: 9
        },
        {
          label: 'Translation',
          value: 13
        },
        {
          label: 'Quality Review',
          value: 14
        },
        {
          label: 'AOD',
          value: 15
        },
        {
          label: 'Mail',
          value: 16
        },
        {
          label: 'Litigation Support',
          value: 18
        },
        {
          label: 'Office of Assessment and Improvement',
          value: 19
        },
        {
          label: 'Office of Chief Counsel',
          value: 20
        },
        {
          label: 'CAVC Litigation Support',
          value: 22
        },
        {
          label: 'Pulac-Cerullo',
          value: 23
        },
        {
          label: 'Hearings Management',
          value: 38
        },
        {
          label: 'Hearing Admin',
          value: 39
        },
        {
          label: 'Executive Management Office',
          value: 70
        },
        {
          label: 'VLJ Support Staff',
          value: 2000000023
        },
        {
          label: 'Special Issue Edit Team',
          value: 74
        }
      ]
    },
    {
      label: 'Death certificate',
      assignedOn: '09/24/2024',
      assignedTo: 'VLJ Support Staff',
      type: 'Organization',
      instructions: [
        'dc'
      ],
      availableActions: [],
      uniqueId: 3209,
      reassignUsers: [
        'CSSID6356001',
        'BVALSPORER',
        'VLJ_SUPPORT_ADMIN'
      ],
      assignedToOrg: true,
      status: 'assigned',
      organizations: [
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
          label: "Pension & Survivor's Benefits",
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
          label: 'Transcription',
          value: 9
        },
        {
          label: 'Translation',
          value: 13
        },
        {
          label: 'Quality Review',
          value: 14
        },
        {
          label: 'AOD',
          value: 15
        },
        {
          label: 'Mail',
          value: 16
        },
        {
          label: 'Privacy Team',
          value: 17
        },
        {
          label: 'Litigation Support',
          value: 18
        },
        {
          label: 'Office of Assessment and Improvement',
          value: 19
        },
        {
          label: 'Office of Chief Counsel',
          value: 20
        },
        {
          label: 'CAVC Litigation Support',
          value: 22
        },
        {
          label: 'Pulac-Cerullo',
          value: 23
        },
        {
          label: 'Hearings Management',
          value: 38
        },
        {
          label: 'Hearing Admin',
          value: 39
        },
        {
          label: 'Executive Management Office',
          value: 70
        },
        {
          label: 'VLJ Support Staff',
          value: 2000000023
        },
        {
          label: 'Special Issue Edit Team',
          value: 74
        }
      ]
    },
    {
      label: 'Privacy complaint',
      assignedOn: '09/24/2024',
      assignedTo: 'Privacy Team',
      type: 'Organization',
      instructions: [
        'pc'
      ],
      availableActions: [],
      uniqueId: 3210,
      reassignUsers: [
        'PRIVACY_TEAM_USER',
        'RETANBVAJ',
        'GOSNEJVACO',
        'SANFORDBVAM'
      ],
      assignedToOrg: true,
      status: 'assigned',
      organizations: [
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
          label: "Pension & Survivor's Benefits",
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
          value: 8
        },
        {
          label: 'Transcription',
          value: 9
        },
        {
          label: 'Translation',
          value: 13
        },
        {
          label: 'Quality Review',
          value: 14
        },
        {
          label: 'AOD',
          value: 15
        },
        {
          label: 'Mail',
          value: 16
        },
        {
          label: 'Litigation Support',
          value: 18
        },
        {
          label: 'Office of Assessment and Improvement',
          value: 19
        },
        {
          label: 'Office of Chief Counsel',
          value: 20
        },
        {
          label: 'CAVC Litigation Support',
          value: 22
        },
        {
          label: 'Pulac-Cerullo',
          value: 23
        },
        {
          label: 'Hearings Management',
          value: 38
        },
        {
          label: 'Hearing Admin',
          value: 39
        },
        {
          label: 'Executive Management Office',
          value: 70
        },
        {
          label: 'VLJ Support Staff',
          value: 2000000023
        },
        {
          label: 'Special Issue Edit Team',
          value: 74
        }
      ]
    }
  ],
  closedTasksUnrelatedToAppeal: [],
  correspondenceAppeals: [
    {
      id: 63,
      correspondencesAppealsTasks: [
        {
          id: 44,
          correspondence_appeal_id: 63,
          task_id: 3203,
          created_at: '2024-09-24T12:54:23.632-04:00',
          updated_at: '2024-09-24T12:54:23.632-04:00'
        },
        {
          id: 45,
          correspondence_appeal_id: 63,
          task_id: 3205,
          created_at: '2024-09-24T12:54:23.696-04:00',
          updated_at: '2024-09-24T12:54:23.696-04:00'
        },
        {
          id: 46,
          correspondence_appeal_id: 63,
          task_id: 3207,
          created_at: '2024-09-24T12:54:23.739-04:00',
          updated_at: '2024-09-24T12:54:23.739-04:00'
        }
      ],
      docketNumber: '240714-447',
      veteranName: {
        id: 101,
        bgs_last_synced_at: null,
        closest_regional_office: null,
        created_at: '2024-07-15T16:47:46.377-04:00',
        date_of_death: null,
        date_of_death_reported_at: null,
        file_number: '550000030',
        first_name: 'Bob',
        last_name: 'Smithbeier',
        middle_name: null,
        name_suffix: '101',
        participant_id: '650000030',
        ssn: '787549808',
        updated_at: '2024-07-15T16:47:46.377-04:00'
      },
      streamType: 'original',
      appealUuid: '0f6bb359-8624-4cef-8690-0891297f224f',
      appealType: 'evidence_submission',
      numberOfIssues: 2,
      appeal: {
        data: {
          id: '447',
          type: 'appeal',
          attributes: {
            assigned_attorney: null,
            assigned_judge: null,
            appellant_hearing_email_recipient: null,
            representative_hearing_email_recipient: null,
            appellant_email_address: 'Bob.Smithbeier@test.com',
            current_user_email: null,
            current_user_timezone: 'America/New_York',
            contested_claim: false,
            mst: null,
            pact: false,
            issues: [],
            status: 'not_distributed',
            decision_issues: [],
            substitute_appellant_claimant_options: [
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
            nod_date_updates: [],
            can_edit_request_issues: false,
            hearings: [],
            withdrawn: false,
            removed: false,
            overtime: false,
            veteran_appellant_deceased: false,
            assigned_to_location: 'Litigation Support',
            distributed_to_a_judge: false,
            'completed_hearing_on_previous_appeal?': false,
            appellant_is_not_veteran: false,
            appellant_full_name: 'Bob Smithbeier',
            appellant_first_name: 'Bob',
            appellant_middle_name: null,
            appellant_last_name: 'Smithbeier',
            appellant_suffix: null,
            appellant_date_of_birth: '1994-07-15',
            appellant_address: {
              address_line_1: '9999 MISSION ST',
              address_line_2: 'UBER',
              address_line_3: 'APT 2',
              city: 'SAN FRANCISCO',
              zip: '94103',
              country: 'USA',
              state: 'CA'
            },
            appellant_phone_number: null,
            appellant_tz: 'America/Los_Angeles',
            appellant_relationship: 'Veteran',
            appellant_type: 'VeteranClaimant',
            appellant_party_type: null,
            unrecognized_appellant_id: null,
            has_poa: {
              id: 30,
              authzn_change_clmant_addrs_ind: null,
              authzn_poa_access_ind: null,
              claimant_participant_id: '650000030',
              created_at: '2024-07-15T16:47:46.454-04:00',
              file_number: '00001234',
              last_synced_at: '2024-07-15T16:47:46.454-04:00',
              legacy_poa_cd: '100',
              poa_participant_id: '600153863',
              representative_name: 'Clarence Darrow',
              representative_type: 'Attorney',
              updated_at: '2024-07-15T16:47:46.454-04:00'
            },
            cavc_remand: null,
            show_post_cavc_stream_msg: false,
            remand_source_appeal_id: null,
            remand_judge_name: null,
            appellant_substitution: null,
            substitutions: [],
            veteran_death_date: null,
            veteran_file_number: '550000030',
            veteran_participant_id: '650000030',
            efolder_link: 'https://vefs-claimevidence-ui-uat.stage.bip.va.gov',
            veteran_full_name: 'Bob Smithbeier',
            closest_regional_office: null,
            closest_regional_office_label: null,
            available_hearing_locations: [],
            external_id: '0f6bb359-8624-4cef-8690-0891297f224f',
            externalId: '0f6bb359-8624-4cef-8690-0891297f224f',
            type: 'Original',
            vacate_type: null,
            aod: false,
            docket_name: 'evidence_submission',
            docket_number: '240714-447',
            docket_range_date: null,
            decision_date: null,
            nod_date: '2024-07-14',
            withdrawal_date: null,
            certification_date: null,
            paper_case: false,
            regional_office: null,
            caseflow_veteran_id: 101,
            document_id: null,
            attorney_case_review_id: null,
            attorney_case_rewrite_details: {
              note_from_attorney: null,
              untimely_evidence: null
            },
            can_edit_document_id: false,
            readable_hearing_request_type: null,
            readable_original_hearing_request_type: null,
            docket_switch: null,
            switched_dockets: [],
            has_notifications: false,
            cavc_remands_with_dashboard: 0,
            evidence_submission_task: {
              id: 2163,
              appeal_id: 447,
              appeal_type: 'Appeal',
              assigned_at: '2024-07-15T16:47:46.499-04:00',
              assigned_by_id: null,
              assigned_to_id: 16,
              assigned_to_type: 'Organization',
              cancellation_reason: null,
              cancelled_by_id: null,
              closed_at: null,
              completed_by_id: null,
              created_at: '2024-07-15T16:47:46.499-04:00',
              instructions: [],
              parent_id: 2162,
              placed_on_hold_at: null,
              started_at: null,
              status: 'assigned',
              updated_at: '2024-07-15T16:47:46.499-04:00'
            },
            has_completed_sct_assign_task: false
          }
        }
      },
      taskAddedData: {
        data: [
          {
            id: '3203',
            type: 'task',
            attributes: {
              is_legacy: false,
              type: 'DeathCertificateMailTask',
              label: 'Death certificate',
              appeal_id: 447,
              status: 'assigned',
              assigned_at: '2024-09-24T12:54:23.602-04:00',
              started_at: null,
              created_at: '2024-09-24T12:54:23.602-04:00',
              closed_at: null,
              cancellation_reason: null,
              instructions: [
                'dc'
              ],
              appeal_type: 'Appeal',
              parent_id: 3202,
              timeline_title: 'DeathCertificateMailTask completed',
              hide_from_queue_table_view: false,
              hide_from_case_timeline: false,
              hide_from_task_snapshot: false,
              assigned_by: {
                first_name: 'Jon',
                last_name: 'Admin',
                full_name: 'Jon MailTeam Snow Admin',
                css_id: 'INBOUND_OPS_TEAM_ADMIN_USER',
                pg_id: 65
              },
              completed_by: null,
              assigned_to: {
                css_id: null,
                full_name: 'VLJ Support Staff',
                is_organization: true,
                name: 'VLJ Support Staff',
                status: 'active',
                type: 'Colocated',
                id: 8
              },
              cancelled_by: {
                css_id: null
              },
              converted_by: {
                css_id: null
              },
              converted_on: null,
              assignee_name: 'VLJ Support Staff',
              placed_on_hold_at: null,
              on_hold_duration: null,
              docket_name: 'evidence_submission',
              case_type: 'Original',
              docket_number: '240714-447',
              docket_range_date: null,
              veteran_full_name: 'Bob Smithbeier',
              veteran_file_number: '550000030',
              closest_regional_office: null,
              external_appeal_id: '0f6bb359-8624-4cef-8690-0891297f224f',
              aod: false,
              overtime: false,
              contested_claim: false,
              mst: null,
              pact: false,
              veteran_appellant_deceased: false,
              issue_count: 0,
              issue_types: '',
              external_hearing_id: null,
              available_hearing_locations: [],
              previous_task: {
                assigned_at: null
              },
              document_id: null,
              decision_prepared_by: {
                first_name: null,
                last_name: null
              },
              available_actions: [],
              can_move_on_docket_switch: true,
              timer_ends_at: null,
              unscheduled_hearing_notes: null,
              appeal_receipt_date: '2024-07-14',
              days_since_last_status_change: 0,
              days_since_board_intake: 0,
              owned_by: 'VLJ Support Staff'
            }
          },
          {
            id: '3205',
            type: 'task',
            attributes: {
              is_legacy: false,
              type: 'AddressChangeMailTask',
              label: 'Change of address',
              appeal_id: 447,
              status: 'assigned',
              assigned_at: '2024-09-24T12:54:23.679-04:00',
              started_at: null,
              created_at: '2024-09-24T12:54:23.679-04:00',
              closed_at: null,
              cancellation_reason: null,
              instructions: [
                'coa'
              ],
              appeal_type: 'Appeal',
              parent_id: 3204,
              timeline_title: 'AddressChangeMailTask completed',
              hide_from_queue_table_view: false,
              hide_from_case_timeline: false,
              hide_from_task_snapshot: false,
              assigned_by: {
                first_name: 'Jon',
                last_name: 'Admin',
                full_name: 'Jon MailTeam Snow Admin',
                css_id: 'INBOUND_OPS_TEAM_ADMIN_USER',
                pg_id: 65
              },
              completed_by: null,
              assigned_to: {
                css_id: null,
                full_name: 'Hearing Admin',
                is_organization: true,
                name: 'Hearing Admin',
                status: 'active',
                type: 'HearingAdmin',
                id: 39
              },
              cancelled_by: {
                css_id: null
              },
              converted_by: {
                css_id: null
              },
              converted_on: null,
              assignee_name: 'Hearing Admin',
              placed_on_hold_at: null,
              on_hold_duration: null,
              docket_name: 'evidence_submission',
              case_type: 'Original',
              docket_number: '240714-447',
              docket_range_date: null,
              veteran_full_name: 'Bob Smithbeier',
              veteran_file_number: '550000030',
              closest_regional_office: null,
              external_appeal_id: '0f6bb359-8624-4cef-8690-0891297f224f',
              aod: false,
              overtime: false,
              contested_claim: false,
              mst: null,
              pact: false,
              veteran_appellant_deceased: false,
              issue_count: 0,
              issue_types: '',
              external_hearing_id: null,
              available_hearing_locations: [],
              previous_task: {
                assigned_at: null
              },
              document_id: null,
              decision_prepared_by: {
                first_name: null,
                last_name: null
              },
              available_actions: [],
              can_move_on_docket_switch: true,
              timer_ends_at: null,
              unscheduled_hearing_notes: null,
              appeal_receipt_date: '2024-07-14',
              days_since_last_status_change: 0,
              days_since_board_intake: 0,
              owned_by: 'Hearing Admin'
            }
          },
          {
            id: '3207',
            type: 'task',
            attributes: {
              is_legacy: false,
              type: 'StatusInquiryMailTask',
              label: 'Status inquiry',
              appeal_id: 447,
              status: 'assigned',
              assigned_at: '2024-09-24T12:54:23.721-04:00',
              started_at: null,
              created_at: '2024-09-24T12:54:23.721-04:00',
              closed_at: null,
              cancellation_reason: null,
              instructions: [
                'si'
              ],
              appeal_type: 'Appeal',
              parent_id: 3206,
              timeline_title: 'StatusInquiryMailTask completed',
              hide_from_queue_table_view: false,
              hide_from_case_timeline: false,
              hide_from_task_snapshot: false,
              assigned_by: {
                first_name: 'Jon',
                last_name: 'Admin',
                full_name: 'Jon MailTeam Snow Admin',
                css_id: 'INBOUND_OPS_TEAM_ADMIN_USER',
                pg_id: 65
              },
              completed_by: null,
              assigned_to: {
                css_id: null,
                full_name: 'Litigation Support',
                is_organization: true,
                name: 'Litigation Support',
                status: 'active',
                type: 'LitigationSupport',
                id: 18
              },
              cancelled_by: {
                css_id: null
              },
              converted_by: {
                css_id: null
              },
              converted_on: null,
              assignee_name: 'Litigation Support',
              placed_on_hold_at: null,
              on_hold_duration: null,
              docket_name: 'evidence_submission',
              case_type: 'Original',
              docket_number: '240714-447',
              docket_range_date: null,
              veteran_full_name: 'Bob Smithbeier',
              veteran_file_number: '550000030',
              closest_regional_office: null,
              external_appeal_id: '0f6bb359-8624-4cef-8690-0891297f224f',
              aod: false,
              overtime: false,
              contested_claim: false,
              mst: null,
              pact: false,
              veteran_appellant_deceased: false,
              issue_count: 0,
              issue_types: '',
              external_hearing_id: null,
              available_hearing_locations: [],
              previous_task: {
                assigned_at: null
              },
              document_id: null,
              decision_prepared_by: {
                first_name: null,
                last_name: null
              },
              available_actions: [],
              can_move_on_docket_switch: true,
              timer_ends_at: null,
              unscheduled_hearing_notes: null,
              appeal_receipt_date: '2024-07-14',
              days_since_last_status_change: 0,
              days_since_board_intake: 0,
              owned_by: 'Litigation Support'
            }
          }
        ]
      },
      status: 'Pending',
      assignedTo: {
        id: 8,
        accepts_priority_pushed_cases: null,
        ama_only_push: false,
        ama_only_request: false,
        created_at: '2024-07-15T16:45:56.066-04:00',
        exclude_appeals_from_affinity: false,
        name: 'VLJ Support Staff',
        participant_id: null,
        role: null,
        status: 'active',
        status_updated_at: null,
        updated_at: '2024-07-15T16:45:56.066-04:00',
        url: 'vlj-support'
      },
      correspondence: {
        id: 63,
        appeal_id: 447,
        correspondence_id: 555,
        created_at: '2024-09-24T12:54:23.566-04:00',
        updated_at: '2024-09-24T12:54:23.566-04:00'
      }
    }
  ],
  veteranFullName: 'Bob Smithbeier',
  veteranFileNumber: '550000030',
  correspondenceAppealIds: [
    '447'
  ],
  correspondenceResponseLetters: [],
  relatedCorrespondenceIds: [],
  file_number: '550000030',
  veteran_name: {
    first_name: 'Bob',
    middle_initial: '',
    last_name: 'Smithbeier'
  },
  correspondence_type_id: 1,
  correspondence_tasks: [
    {
      id: 2986,
      appeal_id: 555,
      appeal_type: 'Correspondence',
      assigned_at: '2024-06-24T21:45:33.609-04:00',
      assigned_by_id: null,
      assigned_to_id: 65,
      assigned_to_type: 'User',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: '2024-08-05T13:54:45.795-04:00',
      completed_by_id: null,
      created_at: '2024-07-15T16:48:16.678-04:00',
      instructions: [],
      parent_id: 2985,
      placed_on_hold_at: null,
      started_at: '2024-08-05T13:54:43.855-04:00',
      status: 'completed',
      updated_at: '2024-08-05T13:54:45.795-04:00',
      type: 'ReviewPackageTask',
      available_actions: []
    },
    {
      id: 2987,
      appeal_id: 555,
      appeal_type: 'Correspondence',
      assigned_at: '2024-06-19T21:48:35.678-04:00',
      assigned_by_id: null,
      assigned_to_id: 74,
      assigned_to_type: 'User',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: null,
      completed_by_id: null,
      created_at: '2024-07-15T16:48:16.717-04:00',
      instructions: [],
      parent_id: 2986,
      placed_on_hold_at: null,
      started_at: '2024-07-15T16:48:16.717-04:00',
      status: 'in_progress',
      updated_at: '2024-07-15T16:48:16.723-04:00',
      type: 'EfolderUploadFailedTask',
      available_actions: []
    },
    {
      id: 3102,
      appeal_id: 555,
      appeal_type: 'Correspondence',
      assigned_at: '2024-08-05T13:54:45.782-04:00',
      assigned_by_id: 65,
      assigned_to_id: 65,
      assigned_to_type: 'User',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: '2024-09-24T12:54:23.534-04:00',
      completed_by_id: null,
      created_at: '2024-08-05T13:54:45.782-04:00',
      instructions: [],
      parent_id: 2985,
      placed_on_hold_at: null,
      started_at: '2024-08-05T13:54:45.782-04:00',
      status: 'completed',
      updated_at: '2024-09-24T12:54:23.534-04:00',
      type: 'CorrespondenceIntakeTask',
      available_actions: []
    },
    {
      id: 3208,
      appeal_id: 555,
      appeal_type: 'Correspondence',
      assigned_at: '2024-09-24T12:54:23.754-04:00',
      assigned_by_id: 65,
      assigned_to_id: 17,
      assigned_to_type: 'Organization',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: null,
      completed_by_id: null,
      created_at: '2024-09-24T12:54:23.754-04:00',
      instructions: [
        'par'
      ],
      parent_id: 2985,
      placed_on_hold_at: null,
      started_at: null,
      status: 'assigned',
      updated_at: '2024-09-24T12:54:23.754-04:00',
      type: 'PrivacyActRequestCorrespondenceTask',
      available_actions: []
    },
    {
      id: 2985,
      appeal_id: 555,
      appeal_type: 'Correspondence',
      assigned_at: '2024-09-24T12:54:23.552-04:00',
      assigned_by_id: null,
      assigned_to_id: 21,
      assigned_to_type: 'Organization',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: null,
      completed_by_id: null,
      created_at: '2024-07-15T16:48:16.661-04:00',
      instructions: [],
      parent_id: null,
      placed_on_hold_at: '2024-09-24T12:54:23.765-04:00',
      started_at: null,
      status: 'on_hold',
      updated_at: '2024-09-24T12:54:23.765-04:00',
      type: 'CorrespondenceRootTask',
      available_actions: []
    },
    {
      id: 3209,
      appeal_id: 555,
      appeal_type: 'Correspondence',
      assigned_at: '2024-09-24T12:54:23.783-04:00',
      assigned_by_id: 65,
      assigned_to_id: 8,
      assigned_to_type: 'Organization',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: null,
      completed_by_id: null,
      created_at: '2024-09-24T12:54:23.783-04:00',
      instructions: [
        'dc'
      ],
      parent_id: 2985,
      placed_on_hold_at: null,
      started_at: null,
      status: 'assigned',
      updated_at: '2024-09-24T12:54:23.783-04:00',
      type: 'DeathCertificateCorrespondenceTask',
      available_actions: []
    },
    {
      id: 3210,
      appeal_id: 555,
      appeal_type: 'Correspondence',
      assigned_at: '2024-09-24T12:54:23.804-04:00',
      assigned_by_id: 65,
      assigned_to_id: 17,
      assigned_to_type: 'Organization',
      cancellation_reason: null,
      cancelled_by_id: null,
      closed_at: null,
      completed_by_id: null,
      created_at: '2024-09-24T12:54:23.804-04:00',
      instructions: [
        'pc'
      ],
      parent_id: 2985,
      placed_on_hold_at: null,
      started_at: null,
      status: 'assigned',
      updated_at: '2024-09-24T12:54:23.804-04:00',
      type: 'PrivacyComplaintCorrespondenceTask',
      available_actions: []
    }
  ],
  mailTasks: [],
  appeals_information: {
    appeals: [
      {
        id: '447',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Litigation Support',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '0f6bb359-8624-4cef-8690-0891297f224f',
          externalId: '0f6bb359-8624-4cef-8690-0891297f224h',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-447',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2163,
            appeal_id: 447,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:46.499-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:46.499-04:00',
            instructions: [],
            parent_id: 2162,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:46.499-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '448',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '7cacf92b-49b9-40d0-9930-1f647c8ac1c6',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-448',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2166,
            appeal_id: 448,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:46.630-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:46.630-04:00',
            instructions: [],
            parent_id: 2165,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:46.630-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '449',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '24074584-9e89-433e-a4b3-46b29306ee75',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-449',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2169,
            appeal_id: 449,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:46.769-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:46.769-04:00',
            instructions: [],
            parent_id: 2168,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:46.769-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '450',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: 'ec54c15c-09f0-47c4-bcee-6db10cb31275',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-450',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2172,
            appeal_id: 450,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:46.916-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:46.916-04:00',
            instructions: [],
            parent_id: 2171,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:46.916-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '451',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '005db2b7-4ec7-45cf-b13a-30ec298a3120',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-451',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2175,
            appeal_id: 451,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:47.064-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:47.064-04:00',
            instructions: [],
            parent_id: 2174,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:47.064-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '452',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '27aed9a0-7769-45d2-85e0-a5375077c1cd',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-452',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2178,
            appeal_id: 452,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:47.212-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:47.212-04:00',
            instructions: [],
            parent_id: 2177,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:47.212-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '453',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '39264db1-ee3a-4f64-8063-b082011d3f0b',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-453',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2181,
            appeal_id: 453,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:47.363-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:47.363-04:00',
            instructions: [],
            parent_id: 2180,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:47.363-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '454',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '2e0d275d-ef6c-4c18-9555-43879fc70305',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-454',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2184,
            appeal_id: 454,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:47.500-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:47.500-04:00',
            instructions: [],
            parent_id: 2183,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:47.500-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '456',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: 'e4728c72-e80e-4e58-8238-d97291a5c465',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-456',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2190,
            appeal_id: 456,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:47.787-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:47.787-04:00',
            instructions: [],
            parent_id: 2189,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:47.787-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '455',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '6baeb092-1bbc-4ddf-9cbd-4a7d9680a7ed',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-455',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2187,
            appeal_id: 455,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:47.636-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:47.636-04:00',
            instructions: [],
            parent_id: 2186,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:47.636-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '457',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: 'dfd2cfac-303f-401c-a169-32083f9f06e5',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-457',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2193,
            appeal_id: 457,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:47.929-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:47.929-04:00',
            instructions: [],
            parent_id: 2192,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:47.929-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '458',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '47c985f6-f3cc-46e3-ad91-d01c594d9c50',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-458',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2196,
            appeal_id: 458,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:48.067-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:48.067-04:00',
            instructions: [],
            parent_id: 2195,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:48.067-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '459',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: 'f90cf0da-f40c-4683-bd95-ac15c63df537',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-459',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2199,
            appeal_id: 459,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:48.209-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:48.209-04:00',
            instructions: [],
            parent_id: 2198,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:48.209-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '460',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '50b20c7e-94fe-42ad-a2a6-84578b3fb0f5',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-460',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2202,
            appeal_id: 460,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:48.350-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:48.350-04:00',
            instructions: [],
            parent_id: 2201,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:48.350-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      },
      {
        id: '461',
        type: 'appeal',
        attributes: {
          contested_claim: false,
          mst: null,
          pact: false,
          issues: [],
          status: 'not_distributed',
          decision_issues: [],
          hearings: [],
          withdrawn: false,
          overtime: false,
          veteran_appellant_deceased: false,
          assigned_to_location: 'Mail',
          distributed_to_a_judge: false,
          appellant_full_name: 'Bob Smithbeier',
          appellant_first_name: 'Bob',
          appellant_middle_name: null,
          appellant_last_name: 'Smithbeier',
          appellant_suffix: null,
          veteran_death_date: null,
          veteran_file_number: '550000030',
          veteran_full_name: 'Bob Smithbeier',
          closest_regional_office: null,
          closest_regional_office_label: null,
          external_id: '0a1aef18-0fa1-42d8-8b0f-7bed22c752f0',
          type: 'Original',
          vacate_type: null,
          aod: false,
          docket_name: 'evidence_submission',
          docket_number: '240714-461',
          docket_range_date: null,
          decision_date: null,
          nod_date: '2024-07-14',
          withdrawal_date: null,
          paper_case: false,
          regional_office: null,
          caseflow_veteran_id: 101,
          docket_switch: null,
          evidence_submission_task: {
            id: 2205,
            appeal_id: 461,
            appeal_type: 'Appeal',
            assigned_at: '2024-07-15T16:47:48.496-04:00',
            assigned_by_id: null,
            assigned_to_id: 16,
            assigned_to_type: 'Organization',
            cancellation_reason: null,
            cancelled_by_id: null,
            closed_at: null,
            completed_by_id: null,
            created_at: '2024-07-15T16:47:48.496-04:00',
            instructions: [],
            parent_id: 2204,
            placed_on_hold_at: null,
            started_at: null,
            status: 'assigned',
            updated_at: '2024-07-15T16:47:48.496-04:00'
          },
          readable_hearing_request_type: null,
          readable_original_hearing_request_type: null
        }
      }
    ],
    claim_reviews: []
  },
  all_correspondences: [
    {
      uuid: '193b4f5e-8868-4ed8-a31d-598b48feadf5',
      id: 555,
      notes: 'This correspondence was originally assigned to and updated by INBOUND_OPS_TEAM_SUPERUSER1.',
      vaDateOfReceipt: '2024-06-16T00:00:00.000-04:00',
      nod: true,
      status: 'Pending',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 613,
          correspondence_id: 555,
          document_file_number: '550000030',
          pages: 19,
          vbms_document_type_id: 1250,
          uuid: '7c5e93da-7fe0-4681-888d-f6817e83e221',
          document_type: 1250,
          document_title: 'VA Form 10182 Notice of Disagreement'
        }
      ],
      correspondenceType: 'Abeyance',
      tasksUnrelatedToAppeal: [
        {
          label: 'Privacy act request',
          assignedOn: '09/24/2024',
          assignedTo: 'Privacy Team',
          type: 'Organization',
          instructions: [
            'par'
          ],
          availableActions: [],
          uniqueId: 3208,
          reassignUsers: [
            'PRIVACY_TEAM_USER',
            'RETANBVAJ',
            'GOSNEJVACO',
            'SANFORDBVAM'
          ],
          assignedToOrg: true,
          status: 'assigned',
          organizations: [
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
              label: "Pension & Survivor's Benefits",
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
              value: 8
            },
            {
              label: 'Transcription',
              value: 9
            },
            {
              label: 'Translation',
              value: 13
            },
            {
              label: 'Quality Review',
              value: 14
            },
            {
              label: 'AOD',
              value: 15
            },
            {
              label: 'Mail',
              value: 16
            },
            {
              label: 'Litigation Support',
              value: 18
            },
            {
              label: 'Office of Assessment and Improvement',
              value: 19
            },
            {
              label: 'Office of Chief Counsel',
              value: 20
            },
            {
              label: 'CAVC Litigation Support',
              value: 22
            },
            {
              label: 'Pulac-Cerullo',
              value: 23
            },
            {
              label: 'Hearings Management',
              value: 38
            },
            {
              label: 'Hearing Admin',
              value: 39
            },
            {
              label: 'Executive Management Office',
              value: 70
            },
            {
              label: 'VLJ Support Staff',
              value: 2000000023
            },
            {
              label: 'Special Issue Edit Team',
              value: 74
            }
          ]
        },
        {
          label: 'Death certificate',
          assignedOn: '09/24/2024',
          assignedTo: 'VLJ Support Staff',
          type: 'Organization',
          instructions: [
            'dc'
          ],
          availableActions: [],
          uniqueId: 3209,
          reassignUsers: [
            'CSSID6356001',
            'BVALSPORER',
            'VLJ_SUPPORT_ADMIN'
          ],
          assignedToOrg: true,
          status: 'assigned',
          organizations: [
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
              label: "Pension & Survivor's Benefits",
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
              label: 'Transcription',
              value: 9
            },
            {
              label: 'Translation',
              value: 13
            },
            {
              label: 'Quality Review',
              value: 14
            },
            {
              label: 'AOD',
              value: 15
            },
            {
              label: 'Mail',
              value: 16
            },
            {
              label: 'Privacy Team',
              value: 17
            },
            {
              label: 'Litigation Support',
              value: 18
            },
            {
              label: 'Office of Assessment and Improvement',
              value: 19
            },
            {
              label: 'Office of Chief Counsel',
              value: 20
            },
            {
              label: 'CAVC Litigation Support',
              value: 22
            },
            {
              label: 'Pulac-Cerullo',
              value: 23
            },
            {
              label: 'Hearings Management',
              value: 38
            },
            {
              label: 'Hearing Admin',
              value: 39
            },
            {
              label: 'Executive Management Office',
              value: 70
            },
            {
              label: 'VLJ Support Staff',
              value: 2000000023
            },
            {
              label: 'Special Issue Edit Team',
              value: 74
            }
          ]
        },
        {
          label: 'Privacy complaint',
          assignedOn: '09/24/2024',
          assignedTo: 'Privacy Team',
          type: 'Organization',
          instructions: [
            'pc'
          ],
          availableActions: [],
          uniqueId: 3210,
          reassignUsers: [
            'PRIVACY_TEAM_USER',
            'RETANBVAJ',
            'GOSNEJVACO',
            'SANFORDBVAM'
          ],
          assignedToOrg: true,
          status: 'assigned',
          organizations: [
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
              label: "Pension & Survivor's Benefits",
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
              value: 8
            },
            {
              label: 'Transcription',
              value: 9
            },
            {
              label: 'Translation',
              value: 13
            },
            {
              label: 'Quality Review',
              value: 14
            },
            {
              label: 'AOD',
              value: 15
            },
            {
              label: 'Mail',
              value: 16
            },
            {
              label: 'Litigation Support',
              value: 18
            },
            {
              label: 'Office of Assessment and Improvement',
              value: 19
            },
            {
              label: 'Office of Chief Counsel',
              value: 20
            },
            {
              label: 'CAVC Litigation Support',
              value: 22
            },
            {
              label: 'Pulac-Cerullo',
              value: 23
            },
            {
              label: 'Hearings Management',
              value: 38
            },
            {
              label: 'Hearing Admin',
              value: 39
            },
            {
              label: 'Executive Management Office',
              value: 70
            },
            {
              label: 'VLJ Support Staff',
              value: 2000000023
            },
            {
              label: 'Special Issue Edit Team',
              value: 74
            }
          ]
        }
      ],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [
        {
          id: 63,
          correspondencesAppealsTasks: [
            {
              id: 44,
              correspondence_appeal_id: 63,
              task_id: 3203,
              created_at: '2024-09-24T12:54:23.632-04:00',
              updated_at: '2024-09-24T12:54:23.632-04:00'
            },
            {
              id: 45,
              correspondence_appeal_id: 63,
              task_id: 3205,
              created_at: '2024-09-24T12:54:23.696-04:00',
              updated_at: '2024-09-24T12:54:23.696-04:00'
            },
            {
              id: 46,
              correspondence_appeal_id: 63,
              task_id: 3207,
              created_at: '2024-09-24T12:54:23.739-04:00',
              updated_at: '2024-09-24T12:54:23.739-04:00'
            }
          ],
          docketNumber: '240714-447',
          veteranName: {
            id: 101,
            bgs_last_synced_at: null,
            closest_regional_office: null,
            created_at: '2024-07-15T16:47:46.377-04:00',
            date_of_death: null,
            date_of_death_reported_at: null,
            file_number: '550000030',
            first_name: 'Bob',
            last_name: 'Smithbeier',
            middle_name: null,
            name_suffix: '101',
            participant_id: '650000030',
            ssn: '787549808',
            updated_at: '2024-07-15T16:47:46.377-04:00'
          },
          streamType: 'original',
          appealUuid: '0f6bb359-8624-4cef-8690-0891297f224f',
          appealType: 'evidence_submission',
          numberOfIssues: 2,
          appeal: {
            data: {
              id: '447',
              type: 'appeal',
              attributes: {
                assigned_attorney: null,
                assigned_judge: null,
                appellant_hearing_email_recipient: null,
                representative_hearing_email_recipient: null,
                appellant_email_address: 'Bob.Smithbeier@test.com',
                current_user_email: null,
                current_user_timezone: 'America/New_York',
                contested_claim: false,
                mst: null,
                pact: false,
                issues: [],
                status: 'not_distributed',
                decision_issues: [],
                substitute_appellant_claimant_options: [
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
                nod_date_updates: [],
                can_edit_request_issues: false,
                hearings: [],
                withdrawn: false,
                removed: false,
                overtime: false,
                veteran_appellant_deceased: false,
                assigned_to_location: 'Litigation Support',
                distributed_to_a_judge: false,
                'completed_hearing_on_previous_appeal?': false,
                appellant_is_not_veteran: false,
                appellant_full_name: 'Bob Smithbeier',
                appellant_first_name: 'Bob',
                appellant_middle_name: null,
                appellant_last_name: 'Smithbeier',
                appellant_suffix: null,
                appellant_date_of_birth: '1994-07-15',
                appellant_address: {
                  address_line_1: '9999 MISSION ST',
                  address_line_2: 'UBER',
                  address_line_3: 'APT 2',
                  city: 'SAN FRANCISCO',
                  zip: '94103',
                  country: 'USA',
                  state: 'CA'
                },
                appellant_phone_number: null,
                appellant_tz: 'America/Los_Angeles',
                appellant_relationship: 'Veteran',
                appellant_type: 'VeteranClaimant',
                appellant_party_type: null,
                unrecognized_appellant_id: null,
                has_poa: {
                  id: 30,
                  authzn_change_clmant_addrs_ind: null,
                  authzn_poa_access_ind: null,
                  claimant_participant_id: '650000030',
                  created_at: '2024-07-15T16:47:46.454-04:00',
                  file_number: '00001234',
                  last_synced_at: '2024-07-15T16:47:46.454-04:00',
                  legacy_poa_cd: '100',
                  poa_participant_id: '600153863',
                  representative_name: 'Clarence Darrow',
                  representative_type: 'Attorney',
                  updated_at: '2024-07-15T16:47:46.454-04:00'
                },
                cavc_remand: null,
                show_post_cavc_stream_msg: false,
                remand_source_appeal_id: null,
                remand_judge_name: null,
                appellant_substitution: null,
                substitutions: [],
                veteran_death_date: null,
                veteran_file_number: '550000030',
                veteran_participant_id: '650000030',
                efolder_link: 'https://vefs-claimevidence-ui-uat.stage.bip.va.gov',
                veteran_full_name: 'Bob Smithbeier',
                closest_regional_office: null,
                closest_regional_office_label: null,
                available_hearing_locations: [],
                external_id: '0f6bb359-8624-4cef-8690-0891297f224f',
                externalId: '0f6bb359-8624-4cef-8690-0891297f224f',
                type: 'Original',
                vacate_type: null,
                aod: false,
                docket_name: 'evidence_submission',
                docket_number: '240714-447',
                docket_range_date: null,
                decision_date: null,
                nod_date: '2024-07-14',
                withdrawal_date: null,
                certification_date: null,
                paper_case: false,
                regional_office: null,
                caseflow_veteran_id: 101,
                document_id: null,
                attorney_case_review_id: null,
                attorney_case_rewrite_details: {
                  note_from_attorney: null,
                  untimely_evidence: null
                },
                can_edit_document_id: false,
                readable_hearing_request_type: null,
                readable_original_hearing_request_type: null,
                docket_switch: null,
                switched_dockets: [],
                has_notifications: false,
                cavc_remands_with_dashboard: 0,
                evidence_submission_task: {
                  id: 2163,
                  appeal_id: 447,
                  appeal_type: 'Appeal',
                  assigned_at: '2024-07-15T16:47:46.499-04:00',
                  assigned_by_id: null,
                  assigned_to_id: 16,
                  assigned_to_type: 'Organization',
                  cancellation_reason: null,
                  cancelled_by_id: null,
                  closed_at: null,
                  completed_by_id: null,
                  created_at: '2024-07-15T16:47:46.499-04:00',
                  instructions: [],
                  parent_id: 2162,
                  placed_on_hold_at: null,
                  started_at: null,
                  status: 'assigned',
                  updated_at: '2024-07-15T16:47:46.499-04:00'
                },
                has_completed_sct_assign_task: false
              }
            }
          },
          taskAddedData: {
            data: [
              {
                id: '3203',
                type: 'task',
                attributes: {
                  is_legacy: false,
                  type: 'DeathCertificateMailTask',
                  label: 'Death certificate',
                  appeal_id: 447,
                  status: 'assigned',
                  assigned_at: '2024-09-24T12:54:23.602-04:00',
                  started_at: null,
                  created_at: '2024-09-24T12:54:23.602-04:00',
                  closed_at: null,
                  cancellation_reason: null,
                  instructions: [
                    'dc'
                  ],
                  appeal_type: 'Appeal',
                  parent_id: 3202,
                  timeline_title: 'DeathCertificateMailTask completed',
                  hide_from_queue_table_view: false,
                  hide_from_case_timeline: false,
                  hide_from_task_snapshot: false,
                  assigned_by: {
                    first_name: 'Jon',
                    last_name: 'Admin',
                    full_name: 'Jon MailTeam Snow Admin',
                    css_id: 'INBOUND_OPS_TEAM_ADMIN_USER',
                    pg_id: 65
                  },
                  completed_by: null,
                  assigned_to: {
                    css_id: null,
                    full_name: 'VLJ Support Staff',
                    is_organization: true,
                    name: 'VLJ Support Staff',
                    status: 'active',
                    type: 'Colocated',
                    id: 8
                  },
                  cancelled_by: {
                    css_id: null
                  },
                  converted_by: {
                    css_id: null
                  },
                  converted_on: null,
                  assignee_name: 'VLJ Support Staff',
                  placed_on_hold_at: null,
                  on_hold_duration: null,
                  docket_name: 'evidence_submission',
                  case_type: 'Original',
                  docket_number: '240714-447',
                  docket_range_date: null,
                  veteran_full_name: 'Bob Smithbeier',
                  veteran_file_number: '550000030',
                  closest_regional_office: null,
                  external_appeal_id: '0f6bb359-8624-4cef-8690-0891297f224f',
                  aod: false,
                  overtime: false,
                  contested_claim: false,
                  mst: null,
                  pact: false,
                  veteran_appellant_deceased: false,
                  issue_count: 0,
                  issue_types: '',
                  external_hearing_id: null,
                  available_hearing_locations: [],
                  previous_task: {
                    assigned_at: null
                  },
                  document_id: null,
                  decision_prepared_by: {
                    first_name: null,
                    last_name: null
                  },
                  available_actions: [],
                  can_move_on_docket_switch: true,
                  timer_ends_at: null,
                  unscheduled_hearing_notes: null,
                  appeal_receipt_date: '2024-07-14',
                  days_since_last_status_change: 0,
                  days_since_board_intake: 0,
                  owned_by: 'VLJ Support Staff'
                }
              },
              {
                id: '3205',
                type: 'task',
                attributes: {
                  is_legacy: false,
                  type: 'AddressChangeMailTask',
                  label: 'Change of address',
                  appeal_id: 447,
                  status: 'assigned',
                  assigned_at: '2024-09-24T12:54:23.679-04:00',
                  started_at: null,
                  created_at: '2024-09-24T12:54:23.679-04:00',
                  closed_at: null,
                  cancellation_reason: null,
                  instructions: [
                    'coa'
                  ],
                  appeal_type: 'Appeal',
                  parent_id: 3204,
                  timeline_title: 'AddressChangeMailTask completed',
                  hide_from_queue_table_view: false,
                  hide_from_case_timeline: false,
                  hide_from_task_snapshot: false,
                  assigned_by: {
                    first_name: 'Jon',
                    last_name: 'Admin',
                    full_name: 'Jon MailTeam Snow Admin',
                    css_id: 'INBOUND_OPS_TEAM_ADMIN_USER',
                    pg_id: 65
                  },
                  completed_by: null,
                  assigned_to: {
                    css_id: null,
                    full_name: 'Hearing Admin',
                    is_organization: true,
                    name: 'Hearing Admin',
                    status: 'active',
                    type: 'HearingAdmin',
                    id: 39
                  },
                  cancelled_by: {
                    css_id: null
                  },
                  converted_by: {
                    css_id: null
                  },
                  converted_on: null,
                  assignee_name: 'Hearing Admin',
                  placed_on_hold_at: null,
                  on_hold_duration: null,
                  docket_name: 'evidence_submission',
                  case_type: 'Original',
                  docket_number: '240714-447',
                  docket_range_date: null,
                  veteran_full_name: 'Bob Smithbeier',
                  veteran_file_number: '550000030',
                  closest_regional_office: null,
                  external_appeal_id: '0f6bb359-8624-4cef-8690-0891297f224f',
                  aod: false,
                  overtime: false,
                  contested_claim: false,
                  mst: null,
                  pact: false,
                  veteran_appellant_deceased: false,
                  issue_count: 0,
                  issue_types: '',
                  external_hearing_id: null,
                  available_hearing_locations: [],
                  previous_task: {
                    assigned_at: null
                  },
                  document_id: null,
                  decision_prepared_by: {
                    first_name: null,
                    last_name: null
                  },
                  available_actions: [],
                  can_move_on_docket_switch: true,
                  timer_ends_at: null,
                  unscheduled_hearing_notes: null,
                  appeal_receipt_date: '2024-07-14',
                  days_since_last_status_change: 0,
                  days_since_board_intake: 0,
                  owned_by: 'Hearing Admin'
                }
              },
              {
                id: '3207',
                type: 'task',
                attributes: {
                  is_legacy: false,
                  type: 'StatusInquiryMailTask',
                  label: 'Status inquiry',
                  appeal_id: 447,
                  status: 'assigned',
                  assigned_at: '2024-09-24T12:54:23.721-04:00',
                  started_at: null,
                  created_at: '2024-09-24T12:54:23.721-04:00',
                  closed_at: null,
                  cancellation_reason: null,
                  instructions: [
                    'si'
                  ],
                  appeal_type: 'Appeal',
                  parent_id: 3206,
                  timeline_title: 'StatusInquiryMailTask completed',
                  hide_from_queue_table_view: false,
                  hide_from_case_timeline: false,
                  hide_from_task_snapshot: false,
                  assigned_by: {
                    first_name: 'Jon',
                    last_name: 'Admin',
                    full_name: 'Jon MailTeam Snow Admin',
                    css_id: 'INBOUND_OPS_TEAM_ADMIN_USER',
                    pg_id: 65
                  },
                  completed_by: null,
                  assigned_to: {
                    css_id: null,
                    full_name: 'Litigation Support',
                    is_organization: true,
                    name: 'Litigation Support',
                    status: 'active',
                    type: 'LitigationSupport',
                    id: 18
                  },
                  cancelled_by: {
                    css_id: null
                  },
                  converted_by: {
                    css_id: null
                  },
                  converted_on: null,
                  assignee_name: 'Litigation Support',
                  placed_on_hold_at: null,
                  on_hold_duration: null,
                  docket_name: 'evidence_submission',
                  case_type: 'Original',
                  docket_number: '240714-447',
                  docket_range_date: null,
                  veteran_full_name: 'Bob Smithbeier',
                  veteran_file_number: '550000030',
                  closest_regional_office: null,
                  external_appeal_id: '0f6bb359-8624-4cef-8690-0891297f224f',
                  aod: false,
                  overtime: false,
                  contested_claim: false,
                  mst: null,
                  pact: false,
                  veteran_appellant_deceased: false,
                  issue_count: 0,
                  issue_types: '',
                  external_hearing_id: null,
                  available_hearing_locations: [],
                  previous_task: {
                    assigned_at: null
                  },
                  document_id: null,
                  decision_prepared_by: {
                    first_name: null,
                    last_name: null
                  },
                  available_actions: [],
                  can_move_on_docket_switch: true,
                  timer_ends_at: null,
                  unscheduled_hearing_notes: null,
                  appeal_receipt_date: '2024-07-14',
                  days_since_last_status_change: 0,
                  days_since_board_intake: 0,
                  owned_by: 'Litigation Support'
                }
              }
            ]
          },
          status: 'Pending',
          assignedTo: {
            id: 8,
            accepts_priority_pushed_cases: null,
            ama_only_push: false,
            ama_only_request: false,
            created_at: '2024-07-15T16:45:56.066-04:00',
            exclude_appeals_from_affinity: false,
            name: 'VLJ Support Staff',
            participant_id: null,
            role: null,
            status: 'active',
            status_updated_at: null,
            updated_at: '2024-07-15T16:45:56.066-04:00',
            url: 'vlj-support'
          },
          correspondence: {
            id: 63,
            appeal_id: 447,
            correspondence_id: 555,
            created_at: '2024-09-24T12:54:23.566-04:00',
            updated_at: '2024-09-24T12:54:23.566-04:00'
          }
        }
      ],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [
        '447'
      ],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: 'f3a9ab30-a577-4d37-82d3-8804bc11cec6',
      id: 552,
      notes: 'Correspondence added to Caseflow on 06/19/24',
      vaDateOfReceipt: '2024-06-19T06:40:20.027-04:00',
      nod: false,
      status: 'Unassigned',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 610,
          correspondence_id: 552,
          document_file_number: '550000030',
          pages: 1,
          vbms_document_type_id: 1452,
          uuid: '51069adf-298c-4f98-81f4-8eb8bec48278',
          document_type: 1452,
          document_title: 'Apportionment - notice to claimant'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: 'b724db40-6e1b-4c13-afe2-4907da91c250',
      id: 558,
      notes: 'This correspondence was originally assigned to and updated by INBOUND_OPS_TEAM_SUPERUSER1.',
      vaDateOfReceipt: '2024-06-21T04:31:19.935-04:00',
      nod: true,
      status: 'Action Required',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 616,
          correspondence_id: 558,
          document_file_number: '550000030',
          pages: 27,
          vbms_document_type_id: 1250,
          uuid: 'e63d55aa-9d99-45ec-90c4-3c5e3ab54863',
          document_type: 1250,
          document_title: 'VA Form 10182 Notice of Disagreement'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '64cf1130-94c4-4f14-8b54-60a5f1eed0bc',
      id: 566,
      notes: 'This correspondence was originally assigned to and updated by INBOUND_OPS_TEAM_SUPERUSER1.',
      vaDateOfReceipt: '2024-06-22T20:26:36.467-04:00',
      nod: false,
      status: 'Pending',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 622,
          correspondence_id: 566,
          document_file_number: '550000030',
          pages: 25,
          vbms_document_type_id: 1430,
          uuid: 'f2250045-e5c9-4e55-979c-c714139abd41',
          document_type: 1430,
          document_title: 'Bank Letter Beneficiary'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [
        {
          label: 'CAVC Correspondence',
          assignedOn: '06/28/2024',
          assignedTo: 'CAVC Litigation Support',
          type: 'Organization',
          instructions: [],
          availableActions: [],
          uniqueId: 3019,
          reassignUsers: [
            'CAVC_LIT_SUPPORT_ADMIN2',
            'CAVC_LIT_SUPPORT_USER1',
            'CAVC_LIT_SUPPORT_USER2',
            'CAVC_LIT_SUPPORT_USER3',
            'CAVC_LIT_SUPPORT_USER4',
            'CAVC_LIT_SUPPORT_USER5',
            'CAVC_LIT_SUPPORT_USER6',
            'CAVC_LIT_SUPPORT_USER7',
            'CAVC_LIT_SUPPORT_USER8',
            'CAVC_LIT_SUPPORT_ADMIN',
            'DELHAUERBVAS',
            'SANFORDBVAM',
            'HARLEKVACO',
            'MINGLLVACO',
            'GOSNEJVACO',
            'CORPRKVACO',
            'PASHBKVACO',
            'NEWMAE1VACO',
            'WILLSBVAJ'
          ],
          assignedToOrg: true,
          status: 'assigned',
          organizations: [
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
              label: "Pension & Survivor's Benefits",
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
              value: 8
            },
            {
              label: 'Transcription',
              value: 9
            },
            {
              label: 'Translation',
              value: 13
            },
            {
              label: 'Quality Review',
              value: 14
            },
            {
              label: 'AOD',
              value: 15
            },
            {
              label: 'Mail',
              value: 16
            },
            {
              label: 'Privacy Team',
              value: 17
            },
            {
              label: 'Litigation Support',
              value: 18
            },
            {
              label: 'Office of Assessment and Improvement',
              value: 19
            },
            {
              label: 'Office of Chief Counsel',
              value: 20
            },
            {
              label: 'Pulac-Cerullo',
              value: 23
            },
            {
              label: 'Hearings Management',
              value: 38
            },
            {
              label: 'Hearing Admin',
              value: 39
            },
            {
              label: 'Executive Management Office',
              value: 70
            },
            {
              label: 'VLJ Support Staff',
              value: 2000000023
            },
            {
              label: 'Special Issue Edit Team',
              value: 74
            }
          ]
        }
      ],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '9f448f39-7f9a-4b62-a659-d7e9cf5b7f6c',
      id: 560,
      notes: 'This correspondence was originally assigned to and updated by INBOUND_OPS_TEAM_SUPERUSER1.',
      vaDateOfReceipt: '2024-06-24T13:03:33.592-04:00',
      nod: true,
      status: 'Action Required',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 618,
          correspondence_id: 560,
          document_file_number: '550000030',
          pages: 28,
          vbms_document_type_id: 1250,
          uuid: 'd08e9bab-da8c-4f94-b334-3f98e3c04fda',
          document_type: 1250,
          document_title: 'VA Form 10182 Notice of Disagreement'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: 'eb5b098f-30cf-4405-9ca0-3578190d0cb9',
      id: 567,
      notes: 'Correspondence Type is a correspondence type.',
      vaDateOfReceipt: '2024-06-26T03:09:10.252-04:00',
      nod: true,
      status: 'Pending',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 623,
          correspondence_id: 567,
          document_file_number: '550000030',
          pages: 24,
          vbms_document_type_id: 1250,
          uuid: 'd5987fae-efd0-4f3f-857b-eb46d698cb5f',
          document_type: 1250,
          document_title: 'VA Form 10182 Notice of Disagreement'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [
        {
          label: 'Congressional interest',
          assignedOn: '06/18/2024',
          assignedTo: 'Litigation Support',
          type: 'Organization',
          instructions: [],
          availableActions: [],
          uniqueId: 3023,
          reassignUsers: [
            'LIT_SUPPORT_USER',
            'DELHAUERBVAS',
            'SANFORDBVAM',
            'HARLEKVACO',
            'MINGLLVACO',
            'LOZANNVACO',
            'SABARMVACO',
            'GOSNEJVACO',
            'CHARLSVACO',
            'PEARSJVACO',
            'CORPRKVACO',
            'GUNTEJVACO',
            'MILLSPVACO',
            'FREDAJVACO',
            'MOORECVACO',
            'WILLIS1VACO',
            'WILLIM9VACO',
            'NEWMAE1VACO',
            'CANNADAYBVAI'
          ],
          assignedToOrg: true,
          status: 'assigned',
          organizations: [
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
              label: "Pension & Survivor's Benefits",
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
              value: 8
            },
            {
              label: 'Transcription',
              value: 9
            },
            {
              label: 'Translation',
              value: 13
            },
            {
              label: 'Quality Review',
              value: 14
            },
            {
              label: 'AOD',
              value: 15
            },
            {
              label: 'Mail',
              value: 16
            },
            {
              label: 'Privacy Team',
              value: 17
            },
            {
              label: 'Office of Assessment and Improvement',
              value: 19
            },
            {
              label: 'Office of Chief Counsel',
              value: 20
            },
            {
              label: 'CAVC Litigation Support',
              value: 22
            },
            {
              label: 'Pulac-Cerullo',
              value: 23
            },
            {
              label: 'Hearings Management',
              value: 38
            },
            {
              label: 'Hearing Admin',
              value: 39
            },
            {
              label: 'Executive Management Office',
              value: 70
            },
            {
              label: 'VLJ Support Staff',
              value: 2000000023
            },
            {
              label: 'Special Issue Edit Team',
              value: 74
            }
          ]
        }
      ],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '1de50f37-c093-4051-831c-5ff20e387063',
      id: 556,
      notes: 'Correspondence Type is a correspondence type.',
      vaDateOfReceipt: '2024-06-26T20:53:34.057-04:00',
      nod: false,
      status: 'Completed',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 614,
          correspondence_id: 556,
          document_file_number: '550000030',
          pages: 28,
          vbms_document_type_id: 1505,
          uuid: '169194a3-b839-46a6-a649-686e7e749046',
          document_type: 1505,
          document_title: 'HLR Not Timely Letter'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '84779b11-67e1-4111-9f82-1141f74272fa',
      id: 554,
      notes: 'This correspondence was originally assigned to and updated by INBOUND_OPS_TEAM_SUPERUSER1.',
      vaDateOfReceipt: '2024-06-30T23:27:59.114-04:00',
      nod: false,
      status: 'Assigned',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 612,
          correspondence_id: 554,
          document_file_number: '550000030',
          pages: 22,
          vbms_document_type_id: 1452,
          uuid: '46016e72-fc6b-45ac-bc3d-64ec870e481a',
          document_type: 1452,
          document_title: 'Apportionment - notice to claimant'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '1df1ba7f-591f-4182-8398-ec79668734ad',
      id: 564,
      notes: 'Correspondence added to Caseflow on 07/01/24',
      vaDateOfReceipt: '2024-07-01T01:04:58.783-04:00',
      nod: false,
      status: 'Completed',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 620,
          correspondence_id: 564,
          document_file_number: '550000030',
          pages: 23,
          vbms_document_type_id: 1430,
          uuid: 'd9b6ac5f-8c21-458d-b9e3-4853acf52cee',
          document_type: 1430,
          document_title: 'Bank Letter Beneficiary'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [
        {
          label: 'CAVC Correspondence',
          assignedOn: '07/15/2024',
          assignedTo: 'Inbound Ops Team',
          type: 'Organization',
          instructions: [],
          availableActions: [],
          uniqueId: 3013,
          status: 'completed'
        }
      ],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '8e537851-4409-48f9-8c55-5f29786fceef',
      id: 559,
      notes: 'This correspondence was originally assigned to and updated by INBOUND_OPS_TEAM_SUPERUSER1.',
      vaDateOfReceipt: '2024-07-01T04:27:12.463-04:00',
      nod: false,
      status: 'Action Required',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 617,
          correspondence_id: 559,
          document_file_number: '550000030',
          pages: 26,
          vbms_document_type_id: 1430,
          uuid: '8d95da59-043f-46d4-a354-73e51f8baccc',
          document_type: 1430,
          document_title: 'Bank Letter Beneficiary'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '661c6412-d4ad-4cee-8eb1-eb9ed870874b',
      id: 570,
      notes: 'Correspondence Type is a correspondence type.',
      vaDateOfReceipt: '2024-07-09T18:57:45.098-04:00',
      nod: true,
      status: 'Unassigned',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 626,
          correspondence_id: 570,
          document_file_number: '550000030',
          pages: 28,
          vbms_document_type_id: 1250,
          uuid: '8d26871e-d797-4eb9-9cbe-564a1f733021',
          document_type: 1250,
          document_title: 'VA Form 10182 Notice of Disagreement'
        },
        {
          id: 627,
          correspondence_id: 570,
          document_file_number: '550000030',
          pages: 30,
          vbms_document_type_id: 1250,
          uuid: 'd2a41c8a-33e5-4e9a-a121-a7ab31c1701a',
          document_type: 1250,
          document_title: 'VA Form 10182 Notice of Disagreement'
        },
        {
          id: 628,
          correspondence_id: 570,
          document_file_number: '550000030',
          pages: 20,
          vbms_document_type_id: 719,
          uuid: '47771be9-f81c-42f4-bf28-2865fdc5e145',
          document_type: 719,
          document_title: 'Exam Request'
        },
        {
          id: 629,
          correspondence_id: 570,
          document_file_number: '550000030',
          pages: 10,
          vbms_document_type_id: 672,
          uuid: 'b3719129-1772-46f5-a905-28eaf3c6c068',
          document_type: 672,
          document_title: 'BVA Letter'
        },
        {
          id: 630,
          correspondence_id: 570,
          document_file_number: '550000030',
          pages: 5,
          vbms_document_type_id: 18,
          uuid: 'fc8e0aed-80f8-41b3-a427-1cb93518100c',
          document_type: 18,
          document_title: 'VA Exam Worksheet'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: 'c53dc28a-e339-454c-be55-effbc11329d7',
      id: 553,
      notes: 'This correspondence was originally assigned to and updated by INBOUND_OPS_TEAM_SUPERUSER1.',
      vaDateOfReceipt: '2024-07-10T06:34:17.914-04:00',
      nod: true,
      status: 'Assigned',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 611,
          correspondence_id: 553,
          document_file_number: '550000030',
          pages: 29,
          vbms_document_type_id: 1250,
          uuid: 'f3afd8a8-834b-4833-857f-10bc431b341f',
          document_type: 1250,
          document_title: 'VA Form 10182 Notice of Disagreement'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: 'd0ce16c2-14e7-4acd-bcbf-73ff3133f497',
      id: 568,
      notes: 'Correspondence added to Caseflow on 07/10/24',
      vaDateOfReceipt: '2024-07-10T14:02:04.525-04:00',
      nod: false,
      status: 'Assigned',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 624,
          correspondence_id: 568,
          document_file_number: '550000030',
          pages: 15,
          vbms_document_type_id: 1452,
          uuid: '0125e85a-327d-475f-8aa8-0bd63d8f76cc',
          document_type: 1452,
          document_title: 'Apportionment - notice to claimant'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '26c09177-33a2-4208-8e98-8ad524debe1f',
      id: 569,
      notes: 'Correspondence Type is Hearing Postponement Request',
      vaDateOfReceipt: '2024-07-11T18:39:12.527-04:00',
      nod: true,
      status: 'Assigned',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 625,
          correspondence_id: 569,
          document_file_number: '550000030',
          pages: 7,
          vbms_document_type_id: 1250,
          uuid: '8913b021-6bae-414b-a10b-19ec3f96f788',
          document_type: 1250,
          document_title: 'VA Form 10182 Notice of Disagreement'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '7b03a2aa-840d-4d49-88fb-82b71d9da198',
      id: 557,
      notes: 'Correspondence Type is CAVC Correspondence',
      vaDateOfReceipt: '2024-07-12T05:17:40.734-04:00',
      nod: true,
      status: 'Assigned',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 615,
          correspondence_id: 557,
          document_file_number: '550000030',
          pages: 28,
          vbms_document_type_id: 1250,
          uuid: 'fef5421a-84f8-4862-8852-3d2677bdf905',
          document_type: 1250,
          document_title: 'VA Form 10182 Notice of Disagreement'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '2ad0d04a-0c79-4141-957f-0572b3bf7965',
      id: 561,
      notes: 'Correspondence Type is a correspondence type.',
      vaDateOfReceipt: '2024-07-12T09:25:56.950-04:00',
      nod: false,
      status: 'Action Required',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 619,
          correspondence_id: 561,
          document_file_number: '550000030',
          pages: 21,
          vbms_document_type_id: 1505,
          uuid: 'b1cad3f3-ccee-4312-a91b-71bf1cacd491',
          document_type: 1505,
          document_title: 'HLR Not Timely Letter'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: 'e2a7edc4-b3d0-4b24-b60e-99c8167c0ac5',
      id: 565,
      notes: 'This correspondence was originally assigned to and updated by INBOUND_OPS_TEAM_SUPERUSER1.',
      vaDateOfReceipt: '2024-07-13T16:24:22.356-04:00',
      nod: false,
      status: 'Unassigned',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 621,
          correspondence_id: 565,
          document_file_number: '550000030',
          pages: 19,
          vbms_document_type_id: 1430,
          uuid: 'c251d1c1-6199-47f2-9c82-38c4a6decc49',
          document_type: 1430,
          document_title: 'Bank Letter Beneficiary'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    }
  ],
  prior_mail: [
    {
      uuid: '64cf1130-94c4-4f14-8b54-60a5f1eed0bc',
      id: 566,
      notes: 'This correspondence was originally assigned to and updated by INBOUND_OPS_TEAM_SUPERUSER1.',
      vaDateOfReceipt: '2024-06-22T20:26:36.467-04:00',
      nod: false,
      status: 'Pending',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 622,
          correspondence_id: 566,
          document_file_number: '550000030',
          pages: 25,
          vbms_document_type_id: 1430,
          uuid: 'f2250045-e5c9-4e55-979c-c714139abd41',
          document_type: 1430,
          document_title: 'Bank Letter Beneficiary'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [
        {
          label: 'CAVC Correspondence',
          assignedOn: '06/28/2024',
          assignedTo: 'CAVC Litigation Support',
          type: 'Organization',
          instructions: [],
          availableActions: [],
          uniqueId: 3019,
          reassignUsers: [
            'CAVC_LIT_SUPPORT_ADMIN2',
            'CAVC_LIT_SUPPORT_USER1',
            'CAVC_LIT_SUPPORT_USER2',
            'CAVC_LIT_SUPPORT_USER3',
            'CAVC_LIT_SUPPORT_USER4',
            'CAVC_LIT_SUPPORT_USER5',
            'CAVC_LIT_SUPPORT_USER6',
            'CAVC_LIT_SUPPORT_USER7',
            'CAVC_LIT_SUPPORT_USER8',
            'CAVC_LIT_SUPPORT_ADMIN',
            'DELHAUERBVAS',
            'SANFORDBVAM',
            'HARLEKVACO',
            'MINGLLVACO',
            'GOSNEJVACO',
            'CORPRKVACO',
            'PASHBKVACO',
            'NEWMAE1VACO',
            'WILLSBVAJ'
          ],
          assignedToOrg: true,
          status: 'assigned',
          organizations: [
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
              label: "Pension & Survivor's Benefits",
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
              value: 8
            },
            {
              label: 'Transcription',
              value: 9
            },
            {
              label: 'Translation',
              value: 13
            },
            {
              label: 'Quality Review',
              value: 14
            },
            {
              label: 'AOD',
              value: 15
            },
            {
              label: 'Mail',
              value: 16
            },
            {
              label: 'Privacy Team',
              value: 17
            },
            {
              label: 'Litigation Support',
              value: 18
            },
            {
              label: 'Office of Assessment and Improvement',
              value: 19
            },
            {
              label: 'Office of Chief Counsel',
              value: 20
            },
            {
              label: 'Pulac-Cerullo',
              value: 23
            },
            {
              label: 'Hearings Management',
              value: 38
            },
            {
              label: 'Hearing Admin',
              value: 39
            },
            {
              label: 'Executive Management Office',
              value: 70
            },
            {
              label: 'VLJ Support Staff',
              value: 2000000023
            },
            {
              label: 'Special Issue Edit Team',
              value: 74
            }
          ]
        }
      ],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: 'eb5b098f-30cf-4405-9ca0-3578190d0cb9',
      id: 567,
      notes: 'Correspondence Type is a correspondence type.',
      vaDateOfReceipt: '2024-06-26T03:09:10.252-04:00',
      nod: true,
      status: 'Pending',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 623,
          correspondence_id: 567,
          document_file_number: '550000030',
          pages: 24,
          vbms_document_type_id: 1250,
          uuid: 'd5987fae-efd0-4f3f-857b-eb46d698cb5f',
          document_type: 1250,
          document_title: 'VA Form 10182 Notice of Disagreement'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [
        {
          label: 'Congressional interest',
          assignedOn: '06/18/2024',
          assignedTo: 'Litigation Support',
          type: 'Organization',
          instructions: [],
          availableActions: [],
          uniqueId: 3023,
          reassignUsers: [
            'LIT_SUPPORT_USER',
            'DELHAUERBVAS',
            'SANFORDBVAM',
            'HARLEKVACO',
            'MINGLLVACO',
            'LOZANNVACO',
            'SABARMVACO',
            'GOSNEJVACO',
            'CHARLSVACO',
            'PEARSJVACO',
            'CORPRKVACO',
            'GUNTEJVACO',
            'MILLSPVACO',
            'FREDAJVACO',
            'MOORECVACO',
            'WILLIS1VACO',
            'WILLIM9VACO',
            'NEWMAE1VACO',
            'CANNADAYBVAI'
          ],
          assignedToOrg: true,
          status: 'assigned',
          organizations: [
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
              label: "Pension & Survivor's Benefits",
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
              value: 8
            },
            {
              label: 'Transcription',
              value: 9
            },
            {
              label: 'Translation',
              value: 13
            },
            {
              label: 'Quality Review',
              value: 14
            },
            {
              label: 'AOD',
              value: 15
            },
            {
              label: 'Mail',
              value: 16
            },
            {
              label: 'Privacy Team',
              value: 17
            },
            {
              label: 'Office of Assessment and Improvement',
              value: 19
            },
            {
              label: 'Office of Chief Counsel',
              value: 20
            },
            {
              label: 'CAVC Litigation Support',
              value: 22
            },
            {
              label: 'Pulac-Cerullo',
              value: 23
            },
            {
              label: 'Hearings Management',
              value: 38
            },
            {
              label: 'Hearing Admin',
              value: 39
            },
            {
              label: 'Executive Management Office',
              value: 70
            },
            {
              label: 'VLJ Support Staff',
              value: 2000000023
            },
            {
              label: 'Special Issue Edit Team',
              value: 74
            }
          ]
        }
      ],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '1de50f37-c093-4051-831c-5ff20e387063',
      id: 556,
      notes: 'Correspondence Type is a correspondence type.',
      vaDateOfReceipt: '2024-06-26T20:53:34.057-04:00',
      nod: false,
      status: 'Completed',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 614,
          correspondence_id: 556,
          document_file_number: '550000030',
          pages: 28,
          vbms_document_type_id: 1505,
          uuid: '169194a3-b839-46a6-a649-686e7e749046',
          document_type: 1505,
          document_title: 'HLR Not Timely Letter'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    },
    {
      uuid: '1df1ba7f-591f-4182-8398-ec79668734ad',
      id: 564,
      notes: 'Correspondence added to Caseflow on 07/01/24',
      vaDateOfReceipt: '2024-07-01T01:04:58.783-04:00',
      nod: false,
      status: 'Completed',
      type: 'Correspondence',
      veteranId: 101,
      correspondenceDocuments: [
        {
          id: 620,
          correspondence_id: 564,
          document_file_number: '550000030',
          pages: 23,
          vbms_document_type_id: 1430,
          uuid: 'd9b6ac5f-8c21-458d-b9e3-4853acf52cee',
          document_type: 1430,
          document_title: 'Bank Letter Beneficiary'
        }
      ],
      correspondenceType: null,
      tasksUnrelatedToAppeal: [],
      closedTasksUnrelatedToAppeal: [
        {
          label: 'CAVC Correspondence',
          assignedOn: '07/15/2024',
          assignedTo: 'Inbound Ops Team',
          type: 'Organization',
          instructions: [],
          availableActions: [],
          uniqueId: 3013,
          status: 'completed'
        }
      ],
      correspondenceAppeals: [],
      veteranFullName: 'Bob Smithbeier',
      veteranFileNumber: '550000030',
      correspondenceAppealIds: [],
      correspondenceResponseLetters: [],
      relatedCorrespondenceIds: []
    }
  ],
  user_access: 'admin_access'
};
