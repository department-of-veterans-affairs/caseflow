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
  correspondenceType: 'Abeyance',
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

export const correspondenceInfoData = {
  correspondenceInfo: {
    tasksUnrelatedToAppeal: [
      {
        label: 'Other motion',
        assignedOn: '11/13/2024',
        assignedTo: 'Litigation Support',
      }
    ]
  }
};

export const appeals = {
  appellantFullName: 'John Doe',
};

export const packageDocumentTypeData = {
  id: 15,
  active: true,
  name: 'NOD',
};
