/* eslint-disable react/prop-types */
import { render, waitFor } from "@testing-library/react";
import React from "react";
import { Provider } from "react-redux";
import { applyMiddleware, createStore } from "redux";
import thunk from "redux-thunk";
import pdfViewerReducer from "../../../../app/reader/PdfViewer/PdfViewerReducer";
import DocumentViewer from "../../../../app/readerprototype/DocumentViewer";
import { MemoryRouter } from "react-router-dom";

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
        filteredDocIds: [1, 2],
        docFilterCriteria: {},
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

describe('Open Document and Test Column Layout', () => {
  it('should change layout from single column to double column at larger width', async () => {
    // Initial render at width 1080 (single column)
    global.innerWidth = 1080;
    const { container } = render(<Component doc={{}} document={{}} />);

    // verify initial width
    expect(global.innerWidth).toBe(1080);

    // Simulate typing 2 into the page number text box
    const pageNumberTextBox = container.querySelector('#page-progress-indicator-input');
    pageNumberTextBox.value = 2;

    // Verify the textbox now holds "2"
    waitFor(() =>
      expect(container).querySelector('#page-progress-indicator-input').value.toBe(2)
    );

    // Now simulate increasing the screen width to 2000px (double column layout)
    global.innerWidth = 2000;
    global.dispatchEvent(new Event('resize'));
    expect(global.innerWidth).toBe(2000);

    // After resizing, the layout should change and the text box should now display 1
    waitFor(() =>
      expect(container).querySelector('#page-progress-indicator-input').value.toBe(1)
    );

    // Simulate a smaller width (1100px), where it should still be a single column layout
    global.innerWidth = 1100;
    global.dispatchEvent(new Event('resize'));
    expect(global.innerWidth).toBe(1100);

    // The page number should still remain 1
    waitFor(() =>
      expect(container).querySelector('#page-progress-indicator-input').value.toBe('1')
    );
  });
});
