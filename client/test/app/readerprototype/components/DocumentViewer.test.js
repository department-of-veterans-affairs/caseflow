import React from 'react';
import { render } from '@testing-library/react';
import { createMemoryHistory } from 'history';
import { Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import DocumentViewer from 'app/readerprototype/DocumentViewer';
import ApiUtil from 'app/util/ApiUtil';
import { rootReducer } from 'app/reader/reducers';

afterEach(() => jest.clearAllMocks());

const mockDocuments = [{ id: 1, type: 'Form 9' }];

const mockShowPdf = jest.fn();

const history = createMemoryHistory();

const defaultProps = {
  allDocuments: mockDocuments,
  match: { params: { docId: '1', vacolsId: '123' } },
  showPdf: mockShowPdf,
  documentPathBase: '/123/documents',
};

const getStore = () =>
  createStore(
    rootReducer,
    {
      pdfViewer: {
        openedAccordionSections: [],
      },
      annotationLayer: {
        deleteAnnotationModalIsOpenFor: null,
        shareAnnotationModalIsOpenFor: null
      },
      documents: {
        1: {
          opened_by_current_user: false
        }
      },
      documentList: {
        pdfList: {
          lastReadDocId: null,
        },
        searchCategoryHighlights: {
          1: {},
          2: {}
        }
      },
    },
    applyMiddleware(thunk)
  );

const Component = (props) => (
  <Provider store={getStore()}>
    <Router history={history}>
      <DocumentViewer {...props} />
    </Router>
  </Provider>
);

describe('user visiting a document', () => {

  beforeEach(() => {
    jest.mock('app/util/ApiUtil', () => ({
      patch: jest.fn(),
    }));
  });

  it('records the viewing of the document', () => {
    const spy = jest.spyOn(ApiUtil, 'patch');

    render(<Component {...defaultProps} />);
    expect(spy).
      toHaveBeenCalledWith(
        '/document/1/mark-as-read',
        { start: '2020-07-06T06:00:00-04:00', t0: 'RUNNING_IN_NODE' },
        'mark-doc-as-read');
  });
});
