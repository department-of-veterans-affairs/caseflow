import { fireEvent, render, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import DocumentViewer from 'app/readerprototype/DocumentViewer';
import React, { useState } from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter, Router } from 'react-router-dom';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import { rootReducer } from 'app/reader/reducers';
import ApiUtil from 'app/util/ApiUtil';
import { documents } from '../data/documents';
import { createMemoryHistory } from 'history';

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

// jest.mock('react-router', () => ({
//   withRouter: jest.fn((Component) => (props) => <Component {...props} history={{}} location={{}} match={{}} />),
// }));

afterEach(() => jest.clearAllMocks());

const defaultProps = (docId) => {
  return {
    allDocuments: [
      documents[1],
      documents[2],
      documents[3],
      documents[4],
      documents[5],
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
      documentList: {
        pdfList: {
          lastReadDocId: null,
        },
        searchCategoryHighlights: [{ 1: {} }, { 2: {} }],
        filteredDocIds: [
          1,
          2,
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

  return (
    <Provider store={getStore()}>
      <MemoryRouter>
        <DocumentViewer {...props} zoomLevel={zoomLevel}
          onZoomChange={(newZoomLevel) => setZoomLevel(newZoomLevel)} />
      </MemoryRouter>
    </Provider>
  );
};

// describe('Marked as Read', () => {
//   beforeEach(() => {
//     jest.mock('app/util/ApiUtil', () => ({
//       patch: jest.fn(),
//     }));
//   });

//   it('marks document with docId 1 as read', () => {
//     const spy = jest.spyOn(ApiUtil, 'patch');

//     render(<Component {...defaultProps('1')} />);
//     expect(spy).toHaveBeenCalledWith('/document/1/mark-as-read', {}, 'mark-doc-as-read');
//   });
// });

describe('Sidebar Section', () => {
  it('closes Issue Tags section and verify it stays closed on next document', async () => {
    const { container, getByText, debug } = render(<Component {...defaultProps('1')} />);

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
    waitFor(() => {
      debug();
      return expect(container).toHaveTextContent('Document 2e of 2');
    });
    // expect(container).toHaveTextContent('Document 2 of 2');
    waitFor(() =>
      expect(container).not.toHaveTextContent('Select or tag issues')
    );
  });
});

// describe('Zoom', () => {
//   it('zooms out and verify zoom level persists on next document', async () => {
//     const { container, getByRole } = render(<Component {...defaultProps('1')} />);

//     expect(container).toHaveTextContent('100%');
//     const zoomOutButton = getByRole('button', { name: /zoom out/i });

//     userEvent.click(zoomOutButton);

//     await waitFor(() => expect(container).toHaveTextContent('90%'));

//     userEvent.click(zoomOutButton);

//     await waitFor(() => expect(container).toHaveTextContent('80%'));
//   });
// });
