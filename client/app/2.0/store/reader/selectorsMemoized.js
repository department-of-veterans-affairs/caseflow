// Local Dependencies
import { documentCategories } from 'store/constants/reader';
import { documentsView, formatTagOptions, formatTagValue, formatCategoryName } from 'utils/reader';
import { createSelector } from 'reselect';
import { isEmpty } from 'lodash';

/**
 * Filtered Documents state
 */

const getFilteredDocIds = (state) => state.reader.documentList.filteredDocIds;
const getAllDocs = (state) => state.reader.documentList.documents;
const getView = (state) => state.reader.documentList.view;
const getSelectedDoc = (state) => state.reader.documentViewer.selected;
const getFilterCriteria = (state) => state.reader.documentList.filterCriteria

export const getFilteredDocuments = createSelector(
  [getFilteredDocIds, getAllDocs],
  (filteredDocIds, allDocs) => filteredDocIds.reduce(
    (list, id) => ({ ...list, [id]: allDocs[id] }),
    {}
  )
)

export const getdocsFiltered = createSelector(
  [getFilterCriteria], (filterCriteria) => {
    return filterCriteria.searchQuery ||
      !isEmpty(filterCriteria.category) ||
      !isEmpty(filterCriteria.tag)
  }
)

/**
 * Selector for the Documents
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Documents
 */
export const documentState = (state) => {
  console.log("Feature Flag Enabled - Bulk Upload")
  // Set the filtered documents
  const documents = getFilteredDocuments(state);

  // Calculate the number of documents
  const docsCount = getFilteredDocIds(state) ?
    getFilteredDocIds(state).length :
    Object.values(documents).length;

  // Return the Filtered Documents and count
  return { documents, docsCount };
};

/**
 * State for the Document List Screen
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Documents List State
 */
export const documentListScreenMemoized = (state) => {
  // Get the filtered documents and count
  const { documents, docsCount } = documentState(state);

  Object.values(getAllDocs(state)).
    reduce((list, doc) => [...list, ...doc.tags], []).
    filter((tags, index, list) => list.findIndex((tag) => tag.text === tags.text) === index);

  const getDocumentsView = createSelector([getAllDocs, getFilterCriteria, getView],
    (docs, filterCriteria, view) => {
      return documentsView(Object.values(docs), filterCriteria, view);
    });

  const docsFiltered = getdocsFiltered(state);

  const documentView = getDocumentsView(state);

  return {
    documents,
    docsCount,
    docsFiltered,
    tagOptions: formatTagOptions(getAllDocs(state)),
    currentDocument: getSelectedDoc(state),
    storeDocuments: getAllDocs(state),
    documentList: state.reader.documentList,
    comments: state.reader.annotationLayer.comments,
    documentsView: documentView,
    filterCriteria: getFilterCriteria(state),
    filteredDocIds: getFilteredDocIds(state),
    searchCategoryHighlights:
      state.reader.documentList.searchCategoryHighlights,
    manifestVbmsFetchedAt: state.reader.documentList.manifestVbmsFetchedAt,
    manifestVvaFetchedAt: state.reader.documentList.manifestVvaFetchedAt,
    queueRedirectUrl: state.reader.documentList.queueRedirectUrl,
    queueTaskType: state.reader.documentList.queueTaskType,
    appeal: state.reader.appeal.selected,
    scale: state.reader.documentViewer.scale,
  };
};

/**
 * State for the Document Screen
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Document State
 */
export const documentScreenMemoized = (state) => {
  // Get the filtered documents and count
  const { documents, docsCount } = documentState(state);

  const getCategories = createSelector(getSelectedDoc, (selectedDoc) => {
    return Object.keys(documentCategories).reduce((list, key) => {
      // Set the current Category
      const cat = selectedDoc[formatCategoryName(key)] ? key : '';
      // Return the Categories Object
      return {
        ...list,
        [cat]: true
      };
    }, {})
  })

  const categories = getCategories(state);
  // Filter the comments for the current document

  const getAllComments = state => state.reader.annotationLayer.comments
  const getComments = createSelector([getAllComments, getSelectedDoc],
    (allComments, selectedDoc) =>
    allComments.filter((comment) =>
    comment.document_id === selectedDoc.id)
    );

  const comments = getComments(state);
  // Get the tag options for the current document
  const getTagOptions = createSelector([getAllDocs],
    (allDocs) => {
      return formatTagValue(
        formatTagOptions(allDocs)
      )
    })
  const tagOptions = getTagOptions(state)

  const docsFiltered = getdocsFiltered(state);


  return {
    documents,
    docsCount,
    categories,
    comments,
    docsFiltered,
    currentPageIndex: state.reader.documentViewer.currentPageIndex,
    pendingTag: state.reader.documentViewer.pendingTag,
    editingTag: state.reader.documentViewer.editingTag,
    pendingCategory: state.reader.documentViewer.pendingCategory,
    documentTags: state.reader.documentViewer.tags,
    tagOptions,
    viewport: state.reader.documentViewer.viewport,
    keyboardInfoOpen: state.reader.documentViewer.keyboardInfoOpen,
    pendingDeletion: state.reader.annotationLayer.pendingDeletion,
    droppedComment: state.reader.annotationLayer.droppedComment,
    editingComment: state.reader.annotationLayer.editingComment,
    addingComment: state.reader.annotationLayer.dropping,
    movingComment: state.reader.annotationLayer.moving,
    savingComment: state.reader.annotationLayer.saving,
    selectedComment: state.reader.annotationLayer.selected,
    search: state.reader.documentViewer.search,
    canvasList: state.reader.documentViewer.canvasList,
    windowingOverscan: state.reader.documentViewer.windowingOverscan,
    deleteCommentId: state.reader.documentViewer.deleteCommentId,
    shareCommentId: state.reader.documentViewer.shareCommentId,
    filterCriteria: getFilterCriteria(state),
    openSections: state.reader.documentViewer.openedAccordionSections,
    currentDocument: getSelectedDoc(state),
    filteredDocIds: getFilteredDocIds(state),
    appeal: state.reader.appeal.selected,
    searchCategoryHighlights:
      state.reader.documentList.searchCategoryHighlights,
    storeDocuments: getAllDocs(state),
    annotationLayer: state.reader.annotationLayer,
    hidePdfSidebar: state.reader.documentViewer.hidePdfSidebar,
    hideSearchBar: state.reader.documentViewer.hideSearchBar,
    scale: state.reader.documentViewer.scale,
    errors: {
      ...state.reader.documentViewer.errors,
      comments: state.reader.annotationLayer.errors,
    },
  };
};
