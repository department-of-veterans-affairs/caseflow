// Local Dependencies
import { documentCategories } from 'store/constants/reader';
import { documentsView, formatTagOptions, formatTagValue, formatCategoryName } from 'utils/reader';
import { isEmpty } from 'lodash';

/**
 * Filtered Documents state
 */
export const filteredDocuments = ({ reader }) =>
  reader.documentList.filteredDocIds.reduce(
    (list, id) => ({ ...list, [id]: reader.documentList.documents[id] }),
    {}
  );

/**
 * Selector for the Documents
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Documents
 */
export const documentState = (state) => {
  // Set the filtered documents
  const documents = filteredDocuments(state);

  // Calculate the number of documents
  const docsCount = state.reader.documentList.filteredDocIds ?
    state.reader.documentList.filteredDocIds.length :
    Object.values(documents).length;

  // Return the Filtered Documents and count
  return { documents, docsCount };
};

/**
 * State for the Document List Screen
 * @param {Object} state -- The current Redux Store state
 * @returns {Object} -- The Documents List State
 */
export const documentListScreen = (state) => {
  // Get the filtered documents and count
  const { documents, docsCount } = documentState(state);

  Object.values(state.reader.documentList.documents).
    reduce((list, doc) => [...list, ...doc.tags], []).
    filter((tags, index, list) => list.findIndex((tag) => tag.text === tags.text) === index);

  return {
    documents,
    docsCount,
    docsFiltered:
      state.reader.documentList.filterCriteria.searchQuery ||
      !isEmpty(state.reader.documentList.filterCriteria.category) ||
      !isEmpty(state.reader.documentList.filterCriteria.tag),
    tagOptions: formatTagOptions(state.reader.documentList.documents),
    currentDocument: state.reader.documentViewer.selected,
    storeDocuments: state.reader.documentList.documents,
    documentList: state.reader.documentList,
    comments: state.reader.annotationLayer.comments,
    documentsView: documentsView(
      Object.values(documents),
      state.reader.documentList.filterCriteria,
      state.reader.documentList.view
    ),
    filterCriteria: state.reader.documentList.filterCriteria,
    filteredDocIds: state.reader.documentList.filteredDocIds,
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
export const documentScreen = (state) => {
  // Get the filtered documents and count
  const { documents, docsCount } = documentState(state);
  const categories = Object.keys(documentCategories).reduce((list, key) => {
    // Set the current Category
    const cat = state.reader.documentViewer.selected[formatCategoryName(key)] ? key : '';

    // Return the Categories Object
    return {
      ...list,
      [cat]: true
    };
  }, {});

  // Filter the comments for the current document
  const comments = state.reader.annotationLayer.comments.filter((comment) =>
    comment.document_id === state.reader.documentViewer.selected.id);

  return {
    documents,
    docsCount,
    categories,
    comments,
    docsFiltered:
      state.reader.documentList.filterCriteria.searchQuery ||
      !isEmpty(state.reader.documentList.filterCriteria.category) ||
      !isEmpty(state.reader.documentList.filterCriteria.tag),
    currentPageIndex: state.reader.documentViewer.currentPageIndex,
    pendingTag: state.reader.documentViewer.pendingTag,
    editingTag: state.reader.documentViewer.editingTag,
    pendingCategory: state.reader.documentViewer.pendingCategory,
    documentTags: state.reader.documentViewer.tags,
    tagOptions: formatTagValue(
      formatTagOptions(state.reader.documentList.documents)
    ),
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
    filterCriteria: state.reader.documentList.filterCriteria,
    openSections: state.reader.documentViewer.openedAccordionSections,
    currentDocument: state.reader.documentViewer.selected,
    filteredDocIds: state.reader.documentList.filteredDocIds,
    appeal: state.reader.appeal.selected,
    searchCategoryHighlights:
      state.reader.documentList.searchCategoryHighlights,
    storeDocuments: state.reader.documentList.documents,
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
