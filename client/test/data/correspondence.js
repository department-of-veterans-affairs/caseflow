export const veteranInformation = {
  id: 1928,
  notes: 'This is a note from CMP',
  veteran_name: {
    first_name: 'Bob',
    middle_name: '',
    last_name: 'Vetner',
  },
  file_number: '998877665',
  correspondence_type_id: 8
};

export const correspondenceData = {
  id: 1,
  assigned_by_id: 81,
  cmp_packet_number: 5555555555,
  cmp_queue_id: 1,
  correspondence_type_id: 8,
  created_at: '2023-11-16 01:44:47.094786',
  notes: 'Some CMP notes here',
  package_document_type_id: 15,
  portal_entry_date: '2023-11-16 01:44:47.080996',
  source_type: 'Mail',
  updated_at: '2023-11-16 01:44:47.094786',
  updated_by_id: null,
  uuid: 'f67702ec-65fb-4b1e-b7c7-d493f7add9e9',
  va_date_of_receipt: '2023-11-15 00:00:00',
  veteran_id: 1928,
};

export const packageDocumentTypeData = {
  id: 15,
  active: true,
  name: '10182',
};

export const correspondenceDocumentsData = [
  {
    correspondence_id: 1,
    document_file_number: veteranInformation.file_number,
    pages: 30,
    vbms_document_id: '1',
    uuid: null,
    document_type: 1250,
    document_title: 'VA Form 10182 Notice of Disagreement'
  },
  {
    correspondence_id: 1,
    document_file_number: veteranInformation.file_number,
    pages: 20,
    vbms_document_id: '1',
    uuid: null,
    document_type: 719,
    document_title: 'Exam Request'
  }
];

export const reviewPackageDataResponse = {
  body: {
    correspondence: correspondenceData,
    package_document_type: packageDocumentTypeData,
    correspondence_documents: correspondenceDocumentsData,
    general_information: veteranInformation
  }
};
