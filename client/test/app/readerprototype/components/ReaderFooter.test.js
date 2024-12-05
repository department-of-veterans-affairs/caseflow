import { fireEvent, render } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ReaderFooter from 'app/readerprototype/components/ReaderFooter';
import React from 'react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import pdfSearchReducer from '../../../../app/reader/PdfSearch/PdfSearchReducer';

const getUnFilteredStore = () =>
  createStore(
    pdfSearchReducer,
    {
      documents: {
        1: {
          id: 1,
          category_medical: null,
          category_other: null,
          category_procedural: null,
          created_at: '2024-08-23T11:13:40.444-04:00',
          description: null,
          file_number: '686623298',
          previous_document_version_id: null,
          received_at: '2024-09-14',
          series_id: '9204496',
          type: 'VA 8 Certification of Appeal',
          updated_at: '2024-09-18T11:35:31.925-04:00',
          upload_date: '2024-09-15',
          vbms_document_id: '100',
          content_url: '/document/1/pdf',
          filename: 'filename-5230058.pdf',
          category_case_summary: true,
          serialized_vacols_date: '',
          serialized_receipt_date: '09/14/2024',
          'matching?': false,
          opened_by_current_user: true,
          tags: [
            {
              id: 1,
              created_at: '2024-08-23T10:02:12.994-04:00',
              text: 'Service Connected',
              updated_at: '2024-08-23T10:02:12.994-04:00'
            }
          ],
          receivedAt: '2024-09-14',
          listComments: false,
          wasUpdated: false
        },
        2: {
          id: 2,
          category_medical: null,
          category_other: null,
          category_procedural: null,
          created_at: '2024-08-23T11:13:40.444-04:00',
          description: null,
          file_number: '686623298',
          previous_document_version_id: null,
          received_at: '2024-09-14',
          series_id: '8175113',
          type: 'Supplemental Statement of the Case',
          updated_at: '2024-09-18T11:35:31.925-04:00',
          upload_date: '2024-09-15',
          vbms_document_id: '101',
          content_url: '/document/2/pdf',
          filename: 'filename-4796387.pdf',
          category_case_summary: true,
          serialized_vacols_date: '',
          serialized_receipt_date: '09/14/2024',
          'matching?': false,
          opened_by_current_user: true,
          tags: [
            {
              id: 2,
              created_at: '2024-08-23T10:02:13.006-04:00',
              text: 'Right Knee',
              updated_at: '2024-08-23T10:02:13.006-04:00'
            }
          ],
          receivedAt: '2024-09-14',
          listComments: false,
          wasUpdated: false
        },
        3: {
          id: 3,
          category_medical: null,
          category_other: null,
          category_procedural: null,
          created_at: '2024-08-23T11:13:40.444-04:00',
          description: null,
          file_number: '686623298',
          previous_document_version_id: null,
          received_at: '2024-09-14',
          series_id: '6766186',
          type: 'CAPRI',
          updated_at: '2024-09-18T11:35:31.925-04:00',
          upload_date: '2024-09-15',
          vbms_document_id: '102',
          content_url: '/document/3/pdf',
          filename: 'filename-5857054.pdf',
          category_case_summary: true,
          serialized_vacols_date: '',
          serialized_receipt_date: '09/14/2024',
          'matching?': false,
          opened_by_current_user: true,
          tags: [],
          receivedAt: '2024-09-14',
          listComments: false,
          wasUpdated: false
        },
        4: {
          id: 4,
          category_medical: null,
          category_other: null,
          category_procedural: null,
          created_at: '2024-08-23T11:13:40.444-04:00',
          description: null,
          file_number: '686623298',
          previous_document_version_id: null,
          received_at: '2024-09-14',
          series_id: '210244',
          type: 'Notice of Disagreement',
          updated_at: '2024-09-18T11:35:31.925-04:00',
          upload_date: '2024-09-15',
          vbms_document_id: '103',
          content_url: '/document/4/pdf',
          filename: 'filename-9812435.pdf',
          category_case_summary: true,
          serialized_vacols_date: '',
          serialized_receipt_date: '09/14/2024',
          'matching?': false,
          opened_by_current_user: true,
          tags: [],
          receivedAt: '2024-09-14',
          listComments: false,
          wasUpdated: false
        },
        5: {
          id: 5,
          category_medical: null,
          category_other: null,
          category_procedural: null,
          created_at: '2024-08-23T11:13:40.444-04:00',
          description: null,
          file_number: '686623298',
          previous_document_version_id: null,
          received_at: '2024-09-14',
          series_id: '9038784',
          type: 'Rating Decision - Codesheet',
          updated_at: '2024-09-18T11:35:31.925-04:00',
          upload_date: '2024-09-15',
          vbms_document_id: '104',
          content_url: '/document/5/pdf',
          filename: 'filename-3019855.pdf',
          category_case_summary: true,
          serialized_vacols_date: '',
          serialized_receipt_date: '09/14/2024',
          'matching?': false,
          opened_by_current_user: true,
          tags: [],
          receivedAt: '2024-09-14',
          listComments: false,
          wasUpdated: false
        },
      },
      documentList: {
        filteredDocIds: [
          1,
          2,
          3,
          4,
          5,
        ],
        docFilterCriteria: {},
      },
      annotationLayer: {
        annotations: 1,
      },
      pdf: {
        pdfDocuments: {},
        documentErrors: {}
      },
    },
    applyMiddleware(thunk)
  );

const getFilteredStore = () =>
  createStore(
    pdfSearchReducer,
    {
      documents: {
        1: {
          id: 1,
          category_medical: null,
          category_other: null,
          category_procedural: null,
          created_at: '2024-08-23T11:13:40.444-04:00',
          description: null,
          file_number: '686623298',
          previous_document_version_id: null,
          received_at: '2024-09-14',
          series_id: '9204496',
          type: 'VA 8 Certification of Appeal',
          updated_at: '2024-09-18T11:35:31.925-04:00',
          upload_date: '2024-09-15',
          vbms_document_id: '100',
          content_url: '/document/1/pdf',
          filename: 'filename-5230058.pdf',
          category_case_summary: true,
          serialized_vacols_date: '',
          serialized_receipt_date: '09/14/2024',
          'matching?': false,
          opened_by_current_user: true,
          tags: [
            {
              id: 1,
              created_at: '2024-08-23T10:02:12.994-04:00',
              text: 'Service Connected',
              updated_at: '2024-08-23T10:02:12.994-04:00'
            }
          ],
          receivedAt: '2024-09-14',
          listComments: false,
          wasUpdated: false
        },
        2: {
          id: 2,
          category_medical: null,
          category_other: null,
          category_procedural: null,
          created_at: '2024-08-23T11:13:40.444-04:00',
          description: null,
          file_number: '686623298',
          previous_document_version_id: null,
          received_at: '2024-09-14',
          series_id: '8175113',
          type: 'Supplemental Statement of the Case',
          updated_at: '2024-09-18T11:35:31.925-04:00',
          upload_date: '2024-09-15',
          vbms_document_id: '101',
          content_url: '/document/2/pdf',
          filename: 'filename-4796387.pdf',
          category_case_summary: true,
          serialized_vacols_date: '',
          serialized_receipt_date: '09/14/2024',
          'matching?': false,
          opened_by_current_user: true,
          tags: [
            {
              id: 2,
              created_at: '2024-08-23T10:02:13.006-04:00',
              text: 'Right Knee',
              updated_at: '2024-08-23T10:02:13.006-04:00'
            }
          ],
          receivedAt: '2024-09-14',
          listComments: false,
          wasUpdated: false
        },
        3: {
          id: 3,
          category_medical: null,
          category_other: null,
          category_procedural: null,
          created_at: '2024-08-23T11:13:40.444-04:00',
          description: null,
          file_number: '686623298',
          previous_document_version_id: null,
          received_at: '2024-09-14',
          series_id: '6766186',
          type: 'CAPRI',
          updated_at: '2024-09-18T11:35:31.925-04:00',
          upload_date: '2024-09-15',
          vbms_document_id: '102',
          content_url: '/document/3/pdf',
          filename: 'filename-5857054.pdf',
          category_case_summary: true,
          serialized_vacols_date: '',
          serialized_receipt_date: '09/14/2024',
          'matching?': false,
          opened_by_current_user: true,
          tags: [],
          receivedAt: '2024-09-14',
          listComments: false,
          wasUpdated: false
        },
        4: {
          id: 4,
          category_medical: null,
          category_other: null,
          category_procedural: null,
          created_at: '2024-08-23T11:13:40.444-04:00',
          description: null,
          file_number: '686623298',
          previous_document_version_id: null,
          received_at: '2024-09-14',
          series_id: '210244',
          type: 'Notice of Disagreement',
          updated_at: '2024-09-18T11:35:31.925-04:00',
          upload_date: '2024-09-15',
          vbms_document_id: '103',
          content_url: '/document/4/pdf',
          filename: 'filename-9812435.pdf',
          category_case_summary: true,
          serialized_vacols_date: '',
          serialized_receipt_date: '09/14/2024',
          'matching?': false,
          opened_by_current_user: true,
          tags: [],
          receivedAt: '2024-09-14',
          listComments: false,
          wasUpdated: false
        },
        5: {
          id: 5,
          category_medical: null,
          category_other: null,
          category_procedural: null,
          created_at: '2024-08-23T11:13:40.444-04:00',
          description: null,
          file_number: '686623298',
          previous_document_version_id: null,
          received_at: '2024-09-14',
          series_id: '9038784',
          type: 'Rating Decision - Codesheet',
          updated_at: '2024-09-18T11:35:31.925-04:00',
          upload_date: '2024-09-15',
          vbms_document_id: '104',
          content_url: '/document/5/pdf',
          filename: 'filename-3019855.pdf',
          category_case_summary: true,
          serialized_vacols_date: '',
          serialized_receipt_date: '09/14/2024',
          'matching?': false,
          opened_by_current_user: true,
          tags: [],
          receivedAt: '2024-09-14',
          listComments: false,
          wasUpdated: false
        },
      },
      documentList: {
        filteredDocIds: [
          4,
          2,
        ],
      },
      annotationLayer: {
        annotations: 1,
      },
      pdf: {
        pdfDocuments: {},
        documentErrors: {}
      },
    },
    applyMiddleware(thunk)
  );

const UnFilteredComponent = (props) => (
  <Provider store={getUnFilteredStore()}>
    <ReaderFooter {...props} />
  </Provider>
);

const FilteredComponent = (props) => (
  <Provider store={getFilteredStore()}>
    <ReaderFooter {...props} />
  </Provider>
);

const doc = {
  id: 4,
  content_url: '/document/4/pdf'
};

describe('Unfiltered', () => {
  it('shows the correct document count', () => {
    const { container } = render(<UnFilteredComponent doc={doc} showPdf={() => jest.fn()} />);

    expect(container).toHaveTextContent('4 of 5');
    expect(container).not.toHaveTextContent('filtered indicator');
  });
});

describe('Filtered', () => {
  it('shows the correct document count', () => {
    const { container } = render(<FilteredComponent currentPage={1} doc={doc} showPdf={() => jest.fn()} />);

    expect(container).toHaveTextContent('1 of 2');
  });

  it('shows the filtered icon', () => {
    const { getByTitle } = render(
      <FilteredComponent currentPage={1} doc={doc} showPdf={() => jest.fn()} />)
    ;

    expect(getByTitle('filtered indicator')).toBeTruthy();
  });
});

describe('Document Navigation', () => {
  const showPdf = jest.fn();

  const doc1 = {
    id: 1,
    content_url: '/document/1/pdf'
  };

  const doc5 = {
    id: 5,
    content_url: '/document/5/pdf'
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('calls showPdf() when Next button is clicked', () => {
    const { container, getByText } = render(<UnFilteredComponent doc={doc1} nextDocId={2} showPdf={() => showPdf} />);

    expect(container).toHaveTextContent('1 of 5');
    expect(container).not.toHaveTextContent('Previous');
    userEvent.click(getByText('Next'));
    expect(showPdf).toHaveBeenCalledTimes(1);
  });

  it('calls showPdf() when Previous button is clicked', () => {
    const { container, getByText } = render(<UnFilteredComponent doc={doc5} prevDocId={4} showPdf={() => showPdf} />);

    expect(container).toHaveTextContent('5 of 5');
    expect(container).not.toHaveTextContent('Next');
    userEvent.click(getByText('Previous'));
    expect(showPdf).toHaveBeenCalledTimes(1);
  });

  it('calls showPdf() when right arrow key is pressed', () => {
    const { container } = render(<UnFilteredComponent doc={doc1} nextDocId={2} showPdf={() => showPdf} />);

    fireEvent.keyDown(container, { key: 'ArrowRight', code: 39 });
    expect(showPdf).toHaveBeenCalledTimes(1);
  });

  it('calls showPdf() when left arrow key is pressed', () => {
    const { container } = render(<UnFilteredComponent doc={doc5} prevDocId={4} showPdf={() => showPdf} />);

    fireEvent.keyDown(container, { key: 'ArrowLeft', code: 37 });
    expect(showPdf).toHaveBeenCalledTimes(1);
  });
});
