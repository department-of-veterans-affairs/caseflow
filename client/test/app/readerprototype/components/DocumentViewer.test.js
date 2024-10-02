import { act, render, screen } from '@testing-library/react';
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

const defaultProps = (docId) => {
  return {
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
      params: { docId, vacolsId: '3575931' },
    },
  };
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
      pdfViewer: {
        hidePdfSidebar: false,
        pdfSideBarError: {
          category: {
            visible: false,
          },
        },
        tagOptions: [],
        openedAccordionSections: ['Issue tags', 'Comments', 'Categories'],
      },
      documentList: {
        pdfList: {
          filters: {},
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
      },
    },
    applyMiddleware(thunk));

const Component = (props) => {
  const [zoomLevel, setZoomLevel] = useState(100);
  const [hidePdfSidebar, togglePdfSidebar] = useState(true);

  return <Provider store={getStore()}>
    <MemoryRouter>
      <DocumentViewer
        zoomLevel={zoomLevel}
        onZoomChange={(newZoomLevel) => setZoomLevel(newZoomLevel)}
        showSideBar={hidePdfSidebar}
        togglePdfSidebar={() => togglePdfSidebar()}
        {...props}
      />
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

    render(<Component {...defaultProps('1')} />);
    expect(spy).toHaveBeenCalledWith('/document/1/mark-as-read', {}, 'mark-doc-as-read');
  });

  it('marks document with docId 4 as read', () => {
    const spy = jest.spyOn(ApiUtil, 'patch');

    render(<Component {...defaultProps('4')} />);
    expect(spy).toHaveBeenCalledWith('/document/4/mark-as-read', {}, 'mark-doc-as-read');
  });
});

// describe('Sidebar Section', () => {
//   beforeEach(() => {
//     jest.clearAllMocks();
//   });

//   it('closes Sidebar and verify it stays closed on the next document', async () => {
//     const { container, getByText, rerender } = render(<Component {...defaultProps('1')} />);

//     act(() => userEvent.click(getByText('Hide menu')));
//     expect(container).toHaveTextContent('Open menu');

//     // act(() => userEvent.click(getByText('Next')));
//     rerender(<Component {...defaultProps('2')} />);
//     expect(document.title).toBe(`${documents[2].type} | Document Viewer | Caseflow Reader`);
//     expect(screen.findByText('Open menu')).toBeInTheDocument();
//   });

//   it('closes Issue Tags section and verify it stays closed on next document', async () => {
//     const { container, getByText, rerender } = render(<Component {...defaultProps('1')} />);

//     expect(document.title).toBe(`${documents[1].type} | Document Viewer | Caseflow Reader`);
//     expect(container).toHaveTextContent('Select or tag issues');
//     expect(container).toHaveTextContent('Add a comment');
//     expect(container).toHaveTextContent('Procedural');
//     expect(container).toHaveTextContent('Document 1 of 5');
//     act(() => userEvent.click(getByText('Issue tags')));
//     expect(container).not.toHaveTextContent('Select or tag issues');

//     // act(() => userEvent.click(getByText('Next')));
//     rerender(<Component {...defaultProps('2')} />);
//     expect(document.title).toBe(`${documents[2].type} | Document Viewer | Caseflow Reader`);
//     expect(container).toHaveTextContent('Document 2 of 5');
//     expect(screen.findByText('Add a comment')).toBeInTheDocument();
//     expect(screen.findByText('Procedural')).toBeInTheDocument();
//     expect(screen.queryByText('Select or tag issues')).not.toBeInTheDocument();
//   });
// });

describe('Zoom', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('zooms out and verify zoom level persists on next document', async() => {
    const { container, getByRole, rerender } = render(<Component {...defaultProps('1')} />);

    expect(container).toHaveTextContent('100%');
    expect(document.title).toBe(`${documents[1].type} | Document Viewer | Caseflow Reader`);
    expect(container).toHaveTextContent('Document 1 of 5');
    act(() => userEvent.click(getByRole('button', { name: /zoom out/i })));
    expect(container).toHaveTextContent('90%');

    // act(() => userEvent.click(getByText('Next')));
    rerender(<Component {...defaultProps('2')} />);
    expect(screen.getByText('90%')).toBeInTheDocument();
    expect(container).toHaveTextContent('Document 2 of 5');
    expect(document.title).toBe(`${documents[2].type} | Document Viewer | Caseflow Reader`);
  });

  it('zooms in and verify zoom level persists on previous document', async() => {
    const { container, getByRole, rerender } = render(<Component {...defaultProps('5')} />);

    expect(container).toHaveTextContent('100%');
    expect(document.title).toBe(`${documents[5].type} | Document Viewer | Caseflow Reader`);
    expect(container).toHaveTextContent('Document 5 of 5');
    act(() => userEvent.click(getByRole('button', { name: /zoom in/i })));
    expect(container).toHaveTextContent('110%');

    // act(() => userEvent.click(getByText('Previous')));
    rerender(<Component {...defaultProps('4')} />);
    expect(screen.getByText('110%')).toBeInTheDocument();
    expect(document.title).toBe(`${documents[4].type} | Document Viewer | Caseflow Reader`);
    expect(container).toHaveTextContent('Document 4 of 5');
  });
});
