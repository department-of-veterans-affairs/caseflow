// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';
import classNames from 'classnames';

// Local Dependencies
import { getPageCoordinatesOfMouseEvent } from 'utils/reader';
import { pdfWrapper } from 'styles/reader/Document/PDF';
import { fetchDocuments, openDownloadLink } from 'utils/reader/document';
import { documentScreen } from 'store/reader/selectors';
import { DocumentHeader } from 'components/reader/DocumentViewer/Header';
import { DocumentSidebar } from 'components/reader/DocumentViewer/Sidebar';
import { DocumentFooter } from 'components/reader/DocumentViewer/Footer';
import { DocumentSearch } from 'app/2.0/components/reader/DocumentViewer/Search';
import { Pdf } from 'app/2.0/components/reader/DocumentViewer/PDF';
import { ZOOM_RATE, MINIMUM_ZOOM, CATEGORIES, PAGE_MARGIN } from 'app/2.0/store/constants/reader';
import { ShareComment } from 'app/2.0/components/reader/DocumentViewer/modals/Share';
import { DeleteComment } from 'app/2.0/components/reader/DocumentViewer/modals/Delete';
import {
  showPdf,
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
import { KeyboardInfo } from 'app/2.0/components/reader/DocumentViewer/modals/KeyboardInfo';

/**
 * Document Viewer Screen Component
 * @param {Object} props -- Contains the route props and PDF web worker
 */
const DocumentViewer = (props) => {
  // Get the Document List state
  const state = useSelector(documentScreen);

  // Create the Dispatcher
  const dispatch = useDispatch();

  // Attach the PDF Worker to the params to setup PDFJS
  const params = {
    ...props.match.params,
    worker: props.pdfWorker,
    currentDocument: state.currentDocument,
    scale: state.scale
  };

  // Calculate the Next and Prev Docs
  const docs = {
    prev: state.filteredDocIds[state.filteredDocIds.indexOf(state.currentDocument.id) - 1],
    current: state.filteredDocIds.indexOf(state.currentDocument.id),
    next: state.filteredDocIds[state.filteredDocIds.indexOf(state.currentDocument.id) + 1],
  };

  // Create the Grid Ref
  const gridRef = React.createRef();

  // Create the dispatchers
  const actions = {
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
          doc: state.currentDocument,
          tag: state.currentDocument.tags.reduce((list, item) => item.text === tag.label ? item : list, {})
        }));
      } else if (values?.length) {
        // Set the tags to create
        const tags = values.
          filter((value) => !state.currentDocument.tags.map((tag) => tag.text).includes(value.label)).
          map((tag) => ({ text: tag.label }));

        // Request the creation of the new tags
        dispatch(addTag({
          doc: state.currentDocument,
          tags
        }));
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
          document_id: state.currentDocument.id,
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
        document_id: state.currentDocument.id,
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
    showPdf: (currentPage, currentDocument, scale) => dispatch(showPdf({
      currentDocument,
      pageNumber: currentPage,
      worker: props.pdfWorker,
      scale
    })),
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
    saveComment: (comment, action = 'save') => {
      // Construct a whitespace-only Regex
      const whitespace = new RegExp(/^\s+$/);

      // Handle empty comments
      if ((whitespace.test(comment.pendingComment) || whitespace.test(comment.comment)) && action === 'save') {
        return dispatch(toggleDeleteModal(comment.id));
      }

      // Calculate the comment data to update/create
      const data = {
        ...comment,
        relevant_date: comment.pendingDate || comment.relevant_date,
        comment: comment.pendingComment || comment.comment
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

      dispatch(searchText({ searchTerm, docId: state.currentDocument.id, matchIndex }));
    },
    saveDescription: (description) => dispatch(saveDescription({ docId: state.currentDocument.id, description })),
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

      dispatch(removeComment({ commentId: state.deleteCommentId, docId: state.currentDocument.id }));
    },
    toggleAccordion: (sections) => dispatch(toggleAccordion(sections, state.openSections)),
    togglePdfSidebar: (open = null) => dispatch(togglePdfSideBar(open)),
    toggleSearchBar: (open = null) => {
      // Toggle the Search
      dispatch(toggleSearchBar(open));

      // Clear the term
      dispatch(searchText({ searchTerm: '', docId: state.currentDocument.id, matchIndex: 0 }));
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
      window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'fit to screen');

      dispatch(showPdf({
        currentDocument: state.currentDocument,
        worker: props.pdfWorker,
        scale: 1
      }));
    },
    rotateDocument: () => {
      dispatch(showPdf({
        currentDocument: state.currentDocument,
        rotation: state.currentDocument.rotation,
        worker: props.pdfWorker,
        scale: state.scale
      }));
    },
    zoom: (direction) => {
      // Determine the Amount to zoom based on the direction
      const delta = direction === 'in' ? ZOOM_RATE : -ZOOM_RATE;

      // Calculate the new Scale to zoom the document
      const scale = Math.min(Math.max(MINIMUM_ZOOM, state.scale + delta), 2);

      window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, `zoom ${direction}`, scale);

      dispatch(showPdf({ currentDocument: state.currentDocument, worker: props.pdfWorker, scale }));
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
    prevDoc: () => {
      // Clear the document search
      dispatch(clearSearch());

      const doc = state.documents[docs.prev];

      // Load the previous doc if found
      if (doc) {
        props.history.push(`/reader/appeal/${params.vacolsId}/documents/${doc.id}`);
      }
    },
    nextDoc: () => {
      // Clear the document search
      dispatch(clearSearch());

      const doc = state.documents[docs.next];

      // Load the next doc if found
      if (doc) {
        props.history.push(`/reader/appeal/${params.vacolsId}/documents/${doc.id}`);
      }
    }
  };

  // Load the Documents
  useEffect(() => {
    // Get the Current document
    const currentDocument = state.documents[params.docId];

    // Load the PDF
    if (currentDocument?.id) {
      dispatch(showPdf({
        currentDocument,
        worker: props.pdfWorker,
        scale: state.scale
      }));
    } else {
      // Load the Documents
      fetchDocuments({ ...state, params }, dispatch)();
    }
  }, [params.docId]);

  return (
    <div id="document-viewer" className="cf-pdf-page-container" onClick={actions.deselectComment} >
      <div className={classNames('cf-pdf-container', { 'hidden-sidebar': state.hidePdfSidebar })} {...pdfWrapper}>
        <DocumentHeader {...props} {...state} {...actions} doc={state.currentDocument} />
        <DocumentSearch {...actions} {...state.search} doc={state.currentDocument} hidden={state.hideSearchBar} />
        <Pdf {...props} {...state}{...actions} doc={state.currentDocument} gridRef={gridRef} />
        <DocumentFooter
          {...props}
          {...state}
          {...actions}
          nextDocId={docs.next > 0 ? docs.next : 0}
          prevDocId={docs.prev > 0 ? docs.prev : 0}
          currentIndex={docs.current}
          doc={state.currentDocument}
        />
      </div>
      <DocumentSidebar {...props} {...state} {...actions} show={!state.hidePdfSidebar} doc={state.currentDocument} />
      <ShareComment {...state} {...actions} show={state.shareCommentId !== null} commentId={state.shareCommentId} />
      <DeleteComment {...state} {...actions} show={state.deleteCommentId !== null} />
      <KeyboardInfo {...state} {...actions} show={state.keyboardInfoOpen} />
    </div>
  );
};

DocumentViewer.propTypes = {
  appeal: PropTypes.object,
  history: PropTypes.object,
  pdfWorker: PropTypes.string,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  singleDocumentMode: PropTypes.bool,
  match: PropTypes.object,
  annotations: PropTypes.array,
};

export default DocumentViewer;
