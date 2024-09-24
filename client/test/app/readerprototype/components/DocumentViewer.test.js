/* eslint-disable react/prop-types */
import { render, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import pdfViewerReducer from '../../../../app/reader/PdfViewer/PdfViewerReducer';
import DocumentViewer from '../../../../app/readerprototype/DocumentViewer';
import { MemoryRouter } from 'react-router-dom';

afterEach(() => jest.clearAllMocks());

const doc = {
  id: 1,
  tags: [],
  category_procedural: true,
  category_other: false,
  category_medical: false,
  category_case_summary: false,
};

const getStore = () =>
  createStore(
    pdfViewerReducer,
    {
      documents: { 1: doc },
      pdfViewer: {
        pdfSideBarError: {
          category: {
            visible: false,
          },
        },
        tagOptions: [],
        openedAccordionSections: ["Issue tags", "Comments", "Categories"],
      },
      documentList: {
        searchCategoryHighlights: [{ 1: {} }, { 2: {} }],
      },
      annotationLayer: {
        annotations: 1,
      },
    },
    applyMiddleware(thunk)
  );

const props = {
  allDocuments: [
    {
      id: 1,
      category_medical: null,
      category_other: null,
      category_procedural: true,
      created_at: "2024-09-17T12:30:52.925-04:00",
      description: null,
      file_number: "216979849",
      previous_document_version_id: null,
      received_at: "2024-09-14",
      series_id: "377120",
      type: "NOD",
      updated_at: "2024-09-17T12:41:11.000-04:00",
      upload_date: "2024-09-15",
      vbms_document_id: "1",
      content_url: "/document/39/pdf",
      filename: "filename-798447.pdf",
      category_case_summary: true,
      serialized_vacols_date: "",
      serialized_receipt_date: "09/14/2024",
      matching: false,
      opened_by_current_user: false,
      tags: [],
      receivedAt: "2024-09-14",
      listComments: false,
      wasUpdated: false,
    },
    {
      id: 2,
      category_medical: null,
      category_other: null,
      category_procedural: true,
      created_at: "2024-09-17T12:30:52.925-04:00",
      description: null,
      file_number: "216979849",
      previous_document_version_id: null,
      received_at: "2024-09-14",
      series_id: "377120",
      type: "NOD",
      updated_at: "2024-09-17T12:41:11.000-04:00",
      upload_date: "2024-09-15",
      vbms_document_id: "1",
      content_url: "/document/39/pdf",
      filename: "filename-798447.pdf",
      category_case_summary: true,
      serialized_vacols_date: "",
      serialized_receipt_date: "09/14/2024",
      matching: false,
      opened_by_current_user: false,
      tags: [],
      receivedAt: "2024-09-14",
      listComments: false,
      wasUpdated: false,
    },
  ],
  showPdf: jest.fn(),
  documentPathBase: "/3575931/documents",
  match: {
    params: { docId: "1", vacolsId: "3575931" },
  },
};

const Component = () => (
  <Provider store={getStore()}>
    <MemoryRouter>
      <DocumentViewer {...props} />
    </MemoryRouter>
  </Provider>
);

describe('Open Document and Close Issue tags Sidebar Section', () => {
  it('Navigate to next document and verify Issue tags stay closed', async () => {
    const { container, getByText } = render(
      <Component doc={doc} document={doc} />
    );

    expect(container).toHaveTextContent('Select or tag issues');
    expect(container).toHaveTextContent('Add a comment');
    expect(container).toHaveTextContent('Procedural');
    expect(container).toHaveTextContent('Document 1 of 2');

    userEvent.click(getByText('Issue tags'));
    waitFor(() =>
      expect(container).not.toHaveTextContent('Select or tag issues')
    );

    userEvent.click(getByText('Next'));
    waitFor(() => expect(container).toHaveTextContent('Add a comment'));
    waitFor(() => expect(container).toHaveTextContent('Procedural'));
    waitFor(() => expect(container).toHaveTextContent('Document 2 of 2'));
    waitFor(() =>
      expect(container).not.toHaveTextContent('Select or tag issues')
    );
  });
});
