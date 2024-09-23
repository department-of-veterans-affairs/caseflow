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
          external_id: "2398523958"
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
          external_id: "2398523958"
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
          external_id: "2398523958"
        }
      }
    }
  }
]

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
