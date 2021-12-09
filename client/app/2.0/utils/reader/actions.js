import {
  togglePdfSideBar,
  toggleSearchBar,
  toggleAccordion,
  toggleShareModal,
  toggleDeleteModal,
  setOverscanValue,
  saveDescription,
  changeDescription,
  resetDescription,
  handleCategoryToggle,
  setPageNumber,
  searchText,
  toggleKeyboardInfo,
  addTag,
  removeTag,
  clearSearch,
  toggleTagEdit
} from 'store/reader/documentViewer';
import {
  selectComment,
  startEdit,
  updateComment,
  saveComment,
  addComment,
  cancelDrop,
  dropComment,
  createComment,
  removeComment,
  startMove,
  moveComment
} from 'store/reader/annotationLayer';
import { getPageCoordinatesOfMouseEvent } from 'utils/reader';
import {
  ROTATION_INCREMENTS,
  COMPLETE_ROTATION,
  ZOOM_RATE,
  MINIMUM_ZOOM,
  CATEGORIES,
  PAGE_MARGIN
} from 'app/2.0/store/constants/reader';
import { openDownloadLink } from 'utils/reader/document';
import { search, renderAllText } from './pdf';

export const documentViewerActions = ({
  pdfId,
  vacolsId,
  state,
  rotation,
  setRotation,
  scale,
  setScale,
  dispatch,
  gridRef,
  pdf,
  history,
  setRendering,
}) => ({
  handleTagEdit: (event) => () => {
    if (event === 'focus') {
      return dispatch(toggleTagEdit(true));
    }

    return dispatch(toggleTagEdit(false));
  },
  changeTags: (values, deleted) => {
    // Delete tags if there are any removed
    if (deleted) {
      // Pull the value to delete out of the list
      const [tag] = deleted;

      // Request the removal of the selected tags
      dispatch(removeTag({
        doc: pdf,
        tag: pdf.tags.reduce((list, item) => item.text === tag.label ? item : list, {})
      }));
    } else if (values?.length) {
      // Set the tags to create
      const tags = values.
        filter((value) => !pdf.tags.map((tag) => tag.text).includes(value.label)).
        map((tag) => ({ text: tag.label }));

      // Request the creation of the new tags
      dispatch(addTag({ id: pdfId, tags }));
    }
  },
  getCoords: (event, pageIndex) => getPageCoordinatesOfMouseEvent(
    event,
    document.getElementById(`comment-layer-${pageIndex}`).getBoundingClientRect(),
    state.scale,
    state.currentDocument.rotation
  ),
  dropComment: (coords, pageIndex) => {
    // Drop the comment at the coordinates
    if (state.addingComment) {
      dispatch(dropComment({
        document_id: pdfId,
        pendingComment: '',
        id: 'placing-annotation-icon',
        page: pageIndex + 1,
        x: coords.x,
        y: coords.y,
      }));
    }
  },
  moveComment: (coords, pageIndex) => {
    // Assign the current icon component
    const icon = document.getElementById(`commentIcon-container-${state.movingComment}`);

    // Calculate the x and y offset by the icon height and width
    const x = (coords.x * state.scale);
    const y = (coords.y * state.scale);

    // Move the Comment in the UI immediately
    icon.style.left = `${x}px`;
    icon.style.top = `${y}px`;

    // Request the move, if failed the comment will revert otherwise it will catch up
    dispatch(moveComment({
      page: pageIndex + 1,
      document_id: pdfId,
      id: state.movingComment,
      x,
      y,
    }));
  },
  moveMouse: (coords, pageIndex) => {
    if (state.addingComment) {
      // Move the cursor icon
      const cursor = document.getElementById(`canvas-cursor-${pageIndex}`);

      // Hide all the other cursors
      Array.from(document.getElementsByClassName('canvas-cursor')).forEach((canvas) => {
        canvas.style.display = 'none';
      });

      // Update the coordinates
      cursor.style.left = `${coords.x * state.scale}px`;
      cursor.style.top = `${coords.y * state.scale}px`;
      cursor.style.display = 'block';
    }
  },
  toggleKeyboardInfo: (val) => dispatch(toggleKeyboardInfo(val)),
  startMove: (commentId) => dispatch(startMove(commentId)),
  clickPage: (event) => {
    event.stopPropagation();
    event.preventDefault();

    if (state.addingComment) {
      dispatch(cancelDrop());
    }

    if (state.selectedComment) {
      dispatch(selectComment({}));
    }
  },
  cancelDrop: () => dispatch(cancelDrop()),
  addComment: () => dispatch(addComment()),
  saveComment: (formData, action = 'save') => {
    // Construct a whitespace-only Regex
    const whitespace = new RegExp(/^\s+$/);

    // Capture the comment
    const comment = formData.pendingComment || formData.comment;

    // Handle empty comments
    if ((whitespace.test(comment) || formData.pendingComment === '')) {
      return dispatch(toggleDeleteModal(formData.id));
    }

    // Calculate the comment data to update/create
    const data = {
      ...formData,
      relevant_date: formData.pendingDate || formData.relevant_date,
      comment
    };

    // Send the analytics event based on the action
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, `request-${action}-annotation`);

    // Determine whether to save or create the comment
    const dispatcher = action === 'create' ? createComment : saveComment;

    // Update the store to either save or create the comment
    dispatch(dispatcher(data));
  },
  updateComment: (comment) => dispatch(updateComment(comment)),
  editComment: (commentId) => dispatch(startEdit(commentId)),
  resetEdit: () => {
    dispatch(updateComment({}));
    dispatch(startEdit(null));
  },
  selectComment: (comment) => dispatch(selectComment(comment)),
  deselectComment: () => {
    if (state.selectedComment) {
      dispatch(selectComment({}));
    }
  },
  searchText: (searchTerm, index) => {

    // Calculate the match index
    const maxIndex = index >= state.search.totalMatchesInFile ? 0 : index;
    const matchIndex = index < 0 ? state.search.totalMatchesInFile - 1 : maxIndex;

    // dispatch(searchText({ searchTerm, docId: pdfId, matchIndex }));
    search({
      searchTerm,
      matchIndex,
      pdfId,
      numPages: pdf.numPages
    });
  },
  saveDescription: (description) => dispatch(saveDescription({ docId: pdfId, description })),
  changeDescription: (description) => dispatch(changeDescription(description)),
  resetDescription: () => dispatch(resetDescription()),
  setOverscanValue: (val) => dispatch(setOverscanValue(val)),
  handleCategoryToggle: (categoryKey, toggleState) => dispatch(handleCategoryToggle({
    docId: state.currentDocument.id,
    categoryKey,
    toggleState
  })),
  closeShareModal: () => dispatch(toggleShareModal(null)),
  closeDeleteModal: () => dispatch(toggleDeleteModal(null)),
  shareComment: (id) => dispatch(toggleShareModal(id)),
  deleteComment: (id) => dispatch(toggleDeleteModal(id)),
  removeComment: () => {
    // Send the analytics event
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'request-delete-annotation');

    dispatch(removeComment({ commentId: state.deleteCommentId, docId: pdfId }));
  },
  toggleAccordion: (sections) => dispatch(toggleAccordion(sections, state.openSections)),
  togglePdfSidebar: (open = null) => dispatch(togglePdfSideBar(open)),
  toggleSearchBar: (open = null) => {
    // Toggle the Search
    dispatch(toggleSearchBar(open));

    renderAllText({ pdf, scale });
    // Clear the term
    // dispatch(searchText({ searchTerm: '', docId: pdfId, matchIndex: 0 }));
  },
  download: () => openDownloadLink(state.currentDocument.content_url, state.currentDocument.type),
  scrollPage: ({ scrollTop }) => {
    // Calculate the Page Offset
    const offset = Math.floor(scrollTop / state.viewport.height);

    // Set the Current page number
    const pageNumber = offset + 1;

    // Calculate the current page
    const currentPage = pageNumber > gridRef.current?.props?.rowCount ? gridRef.current?.props?.rowCount : pageNumber;

    // Update the Pages if the client height and canvas list have changed
    if (pageNumber !== state.currentDocument.currentPage) {
      dispatch(setPageNumber(currentPage));
    }

  },
  overscanIndices: ({ cellCount, overscanCellsCount, startIndex, stopIndex }) => ({
    overscanStartIndex: Math.max(0, startIndex - Math.ceil(overscanCellsCount)),
    overscanStopIndex: Math.min(cellCount - 1, stopIndex + Math.ceil(overscanCellsCount))
  }),
  fitToScreen: () => {
    document.dispatchEvent(new Event('rendering'));

    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'fit to screen');

    setScale(1);
  },
  rotateDocument: () => {
    const newRotation = (rotation + ROTATION_INCREMENTS) % COMPLETE_ROTATION;

    setRotation(newRotation);
  },
  zoom: (direction) => {
    document.dispatchEvent(new Event('rendering'));

    // Determine the Amount to zoom based on the direction
    const delta = direction === 'in' ? ZOOM_RATE : -ZOOM_RATE;

    // Calculate the new Scale to zoom the document
    const newScale = Math.min(Math.max(MINIMUM_ZOOM, scale + delta), 2);

    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, `zoom ${direction}`, newScale);

    setScale(newScale);
  },
  setPageNumber: (pageNumber) => {
    // Add the analytics event
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'jump-to-page');

    // Calculate the page number
    const number = pageNumber - 1;
    const page = number >= gridRef.current?.props?.rowCount ? gridRef.current?.props?.rowCount - 1 : number;

    // Scroll to the page
    gridRef.current?.scrollToPosition({ scrollTop: page * (state.viewport.height + PAGE_MARGIN) });
  },
  prevDoc: (id) => {
    // Clear the document search
    dispatch(clearSearch());

    const doc = state.documents[id];

    // Load the previous doc if found
    if (doc) {
      history.push(`/reader/appeal/${vacolsId}/documents/${id}`);
    }
  },
  nextDoc: (id) => {
    // Clear the document search
    dispatch(clearSearch());

    const doc = state.documents[id];

    // Load the next doc if found
    if (doc) {
      history.push(`/reader/appeal/${vacolsId}/documents/${id}`);
    }
  }
});
