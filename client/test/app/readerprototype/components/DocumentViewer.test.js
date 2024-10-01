import { render, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React, { useState } from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router-dom';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import { rootReducer } from '../../../../app/reader/reducers';
import DocumentViewer from '../../../../app/readerprototype/DocumentViewer';
import ApiUtil from '../../../../app/util/ApiUtil';
import { documents } from '../data/documents';

window.IntersectionObserver = jest.fn(() => ({
  observe: jest.fn(),
  disconnect: jest.fn()
}));
window.HTMLElement.prototype.scrollIntoView = jest.fn;

jest.mock('../../../../app/util/ApiUtil', () => ({
  get: jest.fn().mockResolvedValue({
    body: {
      appeal: {
        data: {}
      }
    },
    header: { 'x-document-source': 'VBMS' }
  }),
  patch: jest.fn().mockResolvedValue({})
}));

jest.mock('../../../../app/util/NetworkUtil', () => ({
  connectionInfo: jest.fn(),
}));

jest.mock('../../../../app/util/Metrics', () => ({
  storeMetrics: jest.fn().mockResolvedValue(),
  recordAsyncMetrics: jest.fn().mockResolvedValue(),
}));

jest.mock('pdfjs-dist', () => ({
  getDocument: jest.fn().mockImplementation(() => ({
    docId: 1,
    promise: Promise.resolve({
      numPages: 2,
      getPage: jest.fn((pageNumber) => ({
        render: jest.fn(pageNumber),
        getTextContent: jest.fn().mockResolvedValue({ items: [] }),
        getViewport: jest.fn(() => ({ width: 100, height: 200 }))
      })),
    }),
  })),
  renderTextLayer: jest.fn(),
  GlobalWorkerOptions: jest.fn().mockResolvedValue(),
}));

const defaultProps = {
  allDocuments: [
    documents[1],
    documents[2],
    documents[3],
    documents[4],
    documents[5]
  ],
  showPdf: jest.fn(),
  documentPathBase: '/3575931/documents',
  match: {
    params: { docId: '1', vacolsId: '3575931' },
  },
};

const getStore = () =>
  createStore(
    rootReducer,
    {
      annotationLayer: {
        annotations: 1,
        deleteAnnotationModalIsOpenFor: null,
        shareAnnotationModalIsOpenFor: null
      },
      documents,
      documentList: {
        pdfList: {
          lastReadDocId: null,
        },
        searchCategoryHighlights: [{ 1: {} }, { 2: {} }],
        filteredDocIds: [
          1,
          2,
          3,
          4,
          5
        ],
        docFilterCriteria: {},
        pdfViewer: {
          pdfSideBarError: {
            category: {
              visible: false,
            },
          },
          tagOptions: [],
          openedAccordionSections: ['Issue tags', 'Comments', 'Categories'],
        },
      },
    },
    applyMiddleware(thunk));

const Component = (props) => {
  const [zoomLevel, setZoomLevel] = useState(100);

  return <Provider store={getStore()}>
    <MemoryRouter>
      <DocumentViewer {...props} zoomLevel={zoomLevel} onZoomChange={(newZoomLevel) => setZoomLevel(newZoomLevel)} />
    </MemoryRouter>
  </Provider>;
};

describe('Marked as Read', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.mock('app/util/ApiUtil', () => ({
      patch: jest.fn(),
    }));
  });

  it('marks document with docId 1 as read', () => {
    const spy = jest.spyOn(ApiUtil, 'patch');

    render(<Component {...defaultProps} />);
    expect(spy).toHaveBeenCalledWith('/document/1/mark-as-read', {}, 'mark-doc-as-read');

  });

  it('marks document with docId 4 as read', () => {
    const spy = jest.spyOn(ApiUtil, 'patch');
    const props = {
      allDocuments: [
        documents[1],
        documents[2],
        documents[3],
        documents[4],
        documents[5]
      ],
      showPdf: jest.fn(),
      documentPathBase: '/3575931/documents',
      match: {
        params: { docId: '4', vacolsId: '3575931' },
      },
    };

    render(<Component {...props} />);
    expect(spy).toHaveBeenCalledWith('/document/4/mark-as-read', {}, 'mark-doc-as-read');
  });
});

describe('Sidebar Section', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('close Issue Tags section and verify it stays closed on next document', async () => {
    const { container, getByText } = render(<Component {...defaultProps} showPdf={jest.fn()} />);

    waitFor(() => expect(document.title).toBe(`${documents[1].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('Select or tag issues'));
    waitFor(() => expect(container).toHaveTextContent('Add a comment'));
    waitFor(() => expect(container).toHaveTextContent('Procedural'));
    waitFor(() => expect(container).toHaveTextContent('Document 1 of 5'));

    waitFor(() => userEvent.click(getByText('Issue tags')));
    waitFor(() => expect(container).not.toHaveTextContent('Select or tag issues'));

    waitFor(() => userEvent.click(getByText('Next')));
    waitFor(() => expect(document.title).toBe(`${documents[2].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('Add a comment'));
    waitFor(() => expect(container).toHaveTextContent('Procedural'));
    waitFor(() => expect(container).toHaveTextContent('Document 2 of 5'));
    waitFor(() => expect(container).not.toHaveTextContent('Select or tag issues'));
  });
});

describe('Zoom', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('zoom out and verify zoom level persists on next document', async() => {
    const { container, getByRole, getByText } = render(<Component {...defaultProps} />);

    waitFor(() => expect(document.title).toBe(`${documents[1].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('100%'));
    waitFor(() => userEvent.click(getByRole('button', { name: /zoom out/i })));
    waitFor(() => expect(container).toHaveTextContent('90%'));

    waitFor(() => userEvent.click(getByText('Next')));
    waitFor(() => expect(document.title).toBe(`${documents[2].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('90%'));
  });

  it('zoom in and verify zoom level persists on previous document', async() => {
    const props = {
      allDocuments: [
        documents[1],
        documents[2],
        documents[3],
        documents[4],
        documents[5]
      ],
      showPdf: jest.fn(),
      documentPathBase: '/3575931/documents',
      match: {
        params: { docId: '5', vacolsId: '3575931' },
      },
    };

    const { container, getByRole, getByText } = render(<Component {...props} showPdf={() => jest.fn()} />);

    waitFor(() => expect(document.title).toBe(`${documents[5].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('100%'));
    waitFor(() => userEvent.click(getByRole('button', { name: /zoom in/i })));
    waitFor(() => expect(container).toHaveTextContent('110%'));

    waitFor(() => userEvent.click(getByText('Previous')));
    waitFor(() => expect(document.title).toBe(`${documents[4].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('110%'));
  });
});
