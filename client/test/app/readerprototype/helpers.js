import { rootReducer } from 'app/reader/reducers';
import { get } from 'bdd-lazy-var/getter';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';

export const defaultStore = (override = {}) => (
  createStore(
    rootReducer,
    {
      annotationLayer: {
        annotations: {},
        deleteAnnotationModalIsOpenFor: null,
        shareAnnotationModalIsOpenFor: null
      },
      documents: { 1: get.document1, 2: get.document2 },
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
        pdf: {
          pdfDocuments: {},
          documentErrors: {}
        },
      },
      ...override
    },
    applyMiddleware(thunk)
  )
);
