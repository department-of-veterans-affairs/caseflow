import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import { rootReducer } from 'app/reader/reducers';
import { get } from 'bdd-lazy-var/getter';

const getStore = (documentListOverride = {}) => (
  createStore(
    rootReducer,
    {
      annotationLayer: {
        annotations: 1,
        deleteAnnotationModalIsOpenFor: null,
        shareAnnotationModalIsOpenFor: null,
      },
      documents: {
        1: get.document1,
        2: get.document2,
        3: get.document3,
        4: get.document4,
        5: get.document5,
      },
      documentList: {
        pdfList: {
          lastReadDocId: null,
        },
        searchCategoryHighlights: [{ 1: {} }, { 2: {} }],
        filteredDocIds: [1, 2, 3, 4, 5],
        docFilterCriteria: {},
        ...documentListOverride
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
