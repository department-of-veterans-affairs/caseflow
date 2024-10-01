import { fireEvent, render, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router-dom';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import { rootReducer } from '../../../../app/reader/reducers';
import ReaderFooter from '../../../../app/readerprototype/components/ReaderFooter';
import { documents } from '../data/documents';
import DocumentViewer from '../../../../app/readerprototype/DocumentViewer';

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

afterEach(() => {
  jest.clearAllMocks();
});

const getUnFilteredStore = () =>
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

const getFilteredStore = () =>
  createStore(
    rootReducer,
    {
      documents,
      documentList: {
        filteredDocIds: [
          4,
          2,
        ],
      },
      annotationLayer: {
        annotations: 1,
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
};

describe('Unfiltered', () => {
  it('shows the correct document count', () => {
    const { container } = render(<UnFilteredComponent docId={doc.id} showPdf={() => jest.fn()} />);

    expect(container).toHaveTextContent('4 of 5');
    expect(container).not.toHaveTextContent('filtered indicator');
  });
});

describe('Filtered', () => {
  it('shows the correct document count', () => {
    const { container } = render(<FilteredComponent currentPage={1} docId={doc.id} numPages={2} showPdf={() => jest.fn()} />);

    expect(container).toHaveTextContent('1 of 2');
  });

  it('shows the filtered icon', () => {
    const { getByTitle } = render(
      <FilteredComponent currentPage={1} docId={doc.id} numPages={2} showPdf={() => jest.fn()} />)
    ;

    expect(getByTitle('filtered indicator')).toBeTruthy();
  });
});

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

const Component = (props) => {

  return <Provider store={getUnFilteredStore()}>
    <MemoryRouter>
      <DocumentViewer {...props} />
    </MemoryRouter>
  </Provider>;
};

describe('Document Navigation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('navigates to the next document and updates browser tab', async() => {
    const { container, getByText } = render(<Component {...defaultProps} showPdf={() => jest.fn()} />);

    waitFor(() => expect(document.title).toBe(`${documents[1].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('Document 1 of 5'));
    expect(container).not.toHaveTextContent('Previous');

    waitFor(() => userEvent.click(getByText('Next')));
    waitFor(() => expect(document.title).toBe(`${documents[2].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('Document 2 of 5'));
    waitFor(() => expect(container).toHaveTextContent('Previous'));

    fireEvent.keyDown(container, { key: 'ArrowRight', code: 39 });
    waitFor(() => expect(document.title).toBe(`${documents[3].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('Document 3 of 5'));
    waitFor(() => expect(container).toHaveTextContent('Previous'));
  });

  it('navigates to the previous document and updates browser tab', async() => {
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

    const { container, getByText } = render(<Component {...props} showPdf={() => jest.fn()} />);

    waitFor(() => expect(document.title).toBe(`${documents[5].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('Document 5 of 5'));
    expect(container).not.toHaveTextContent('Next');

    waitFor(() => userEvent.click(getByText('Previous')));
    waitFor(() => expect(document.title).toBe(`${documents[4].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('Document 4 of 5'));
    waitFor(() => expect(container).toHaveTextContent('Next'));

    fireEvent.keyDown(container, { key: 'ArrowLeft', code: 37 });
    waitFor(() => expect(document.title).toBe(`${documents[3].type} | Document Viewer | Caseflow Reader`));
    waitFor(() => expect(container).toHaveTextContent('Document 3 of 5'));
    waitFor(() => expect(container).toHaveTextContent('Next'));
  });
});

