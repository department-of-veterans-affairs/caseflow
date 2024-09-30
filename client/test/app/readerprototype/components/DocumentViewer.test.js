import { fireEvent, render, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import DocumentViewer from 'app/readerprototype/DocumentViewer';
import React, { useState } from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router-dom';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import { rootReducer } from 'app/reader/reducers';
import ApiUtil from 'app/util/ApiUtil';
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

afterEach(() => jest.clearAllMocks());

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
      <DocumentViewer {...props} zoomLevel={zoomLevel}
        onZoomChange={(newZoomLevel) => setZoomLevel(newZoomLevel)} />
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

describe('Open Document and Close Issue tags Sidebar Section', () => {
  it('Navigate to next document and verify Issue tags stay closed', async () => {
    const { container, getByText } = render(<Component {...defaultProps} />);

    expect(container).toHaveTextContent('Select or tag issues');
    expect(container).toHaveTextContent('Add a comment');
    expect(container).toHaveTextContent('Procedural');
    expect(container).toHaveTextContent('Document 1 of 5');

    userEvent.click(getByText('Issue tags'));
    waitFor(() =>
      expect(container).not.toHaveTextContent('Select or tag issues')
    );

    userEvent.click(getByText('Next'));
    waitFor(() => expect(container).toHaveTextContent('Add a comment'));
    waitFor(() => expect(container).toHaveTextContent('Procedural'));
    waitFor(() => expect(container).toHaveTextContent('Document 2 of 5'));
    waitFor(() =>
      expect(container).not.toHaveTextContent('Select or tag issues')
    );

  });
});

describe('Zoom', () => {
  it('updates zoom level when zoom out button clicked', async() => {
    const { container, getByRole } = render(<Component {...defaultProps} />);

    expect(container).toHaveTextContent('100%');
    const zoomOutButton = getByRole('button', { name: /zoom out/i });

    userEvent.click(zoomOutButton);
    await waitFor(() => expect(container).toHaveTextContent('90%'));
    userEvent.click(zoomOutButton);
    await waitFor(() => expect(container).toHaveTextContent('80%'));
  });
});

describe('Document Navigation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('navigates to the next document when Next button or right arrow key is pressed', async() => {
    const { container, getByText } = render(<Component {...defaultProps} />);

    expect(container).toHaveTextContent('1 of 5');
    expect(container).not.toHaveTextContent('Previous');
    userEvent.click(getByText('Next'));
    waitFor(() => expect(container).toHaveTextContent('Document 2 of 5'));
    userEvent.click(getByText('Next'));
    waitFor(() => expect(container).toHaveTextContent('Document 3 of 5'));
  });

  it('navigates to the previous document when Previous button or left arrow key is pressed', async() => {
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

    const { container, getByText } = render(<Component {...props} />);

    expect(container).toHaveTextContent('5 of 5');
    expect(container).not.toHaveTextContent('Next');
    userEvent.click(getByText('Previous'));
    waitFor(() => expect(container).toHaveTextContent('Document 4 of 5'));
    userEvent.click(getByText('Previous'));
    waitFor(() => expect(container).toHaveTextContent('Document 3 of 5'));
  });
});
