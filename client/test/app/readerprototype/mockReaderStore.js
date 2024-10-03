import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import { rootReducer } from 'app/reader/reducers';
import { documentFactory } from './factories';

const getStore = (overrides = {}) => (
  createStore(
    rootReducer,
    {
      annotationLayer: {
        annotations: 1,
        deleteAnnotationModalIsOpenFor: null,
        shareAnnotationModalIsOpenFor: null,
      },
      documents: {
        1: documentFactory(),
        2: documentFactory(),
        3: documentFactory(),
        4: documentFactory(),
        5: documentFactory(),
        ...overrides
      },
      documentList: {
        pdfList: {
          lastReadDocId: null,
        },
        searchCategoryHighlights: [{ 1: {} }, { 2: {} }],
        filteredDocIds: [1],
        docFilterCriteria: {},
        ...overrides
      },
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
    },
    applyMiddleware(thunk)
  )
);

export default getStore;
