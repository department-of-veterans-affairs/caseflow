import { createSlice, createAction, createAsyncThunk } from '@reduxjs/toolkit';
import { differenceWith, differenceBy, find, pick, random, range } from 'lodash';
import uuid from 'uuid';
import * as PDF from 'pdfjs';
import Mark from 'mark.js';

// Local Dependencies
import ApiUtil from 'app/util/ApiUtil';
import {
  PDF_PAGE_HEIGHT,
  PDF_PAGE_WIDTH,
  ENDPOINT_NAMES,
  ROTATION_INCREMENTS,
  COMPLETE_ROTATION,
  COMMENT_ACCORDION_KEY
} from 'store/constants/reader';
import { addMetaLabel, formatCategoryName } from 'utils/reader';
import { removeComment } from 'store/reader/annotationLayer';

// Create a place in-memory to store the downloaded PDF documents
const pdfDocuments = {};

/**
 * PDF SideBar Error State
 */
const initialPdfSidebarErrorState = {
  tag: { visible: false, message: null },
  category: { visible: false, message: null },
  annotation: { visible: false, message: null },
  description: { visible: false, message: null }
};

/**
 * PDF Initial State
 */
export const initialState = {
  viewport: {
    height: PDF_PAGE_HEIGHT,
    width: PDF_PAGE_WIDTH,
  },
  canvasList: [],
  hideSearchBar: true,
  hidePdfSidebar: false,
  scrollToComment: null,
  pageDimensions: {},
  documentErrors: {},
  text: [],
  selected: {},
  loading: false,
  keyboardInfoOpen: false,
  openedAccordionSections: ['Categories', 'Issue tags', COMMENT_ACCORDION_KEY],
  tagOptions: {},
  jumpToPageNumber: null,
  scrollTop: 0,
  pdfSideBarError: initialPdfSidebarErrorState,
  scrollToSidebarComment: null,
  scale: 1,
  windowingOverscan: random(5, 10).toString(),
  deleteCommentId: null,
  shareCommentId: null,
  search: {
    scrollPosition: null,
    searchTerm: '',
    matchIndex: 0,
    indexToHighlight: null,
    relativeIndex: 0,
    pageIndexWithMatch: null,
    extractedText: {},
    totalMatchesInFile: 0
  }
};

/**
 * Dispatcher for Extracting text from PDF Documents and searching
 */
export const searchText = createAsyncThunk('documentViewer/search', async ({
  matchIndex,
  searchTerm,
  docId
}) => {
  // Create the list of text layer containers
  const layers = [];

  // Map the Extract to promises
  const textPromises = range(pdfDocuments[docId].pdf.numPages).map((index) =>
    pdfDocuments[docId].pdf.getPage(index + 1).then((page) => page.getTextContent()));

  // Wait for the search to complete
  const pages = await Promise.all(textPromises);

  // Create the Regex Match
  const regex = new RegExp(searchTerm ? searchTerm.replace(/[-[\]/{}()*+?.\\^$|]/g, '\\$&') : null, 'gi');

  // Calculate the Search Matches
  const match = (page) => (page.items.map((row) => row.str).join(' ').
    match(regex) || []).length;

  // Reduce the Pages to an object containing the matches
  const matches = pages.reduce((count, page) => count + match(page), 0);

  // Render the text layer
  const pageList = pages.map((page, index) => {
    // Retrieve the text layer element
    layers[index] = document.getElementById(`text-${index}`);

    // Reset the container contents
    layers[index].innerHTML = '';

    return PDF.renderTextLayer({
      container: layers[index],
      textContent: page,
      viewport: pdfDocuments[docId].viewport,
      textDivs: []
    }).promise;
  });

  // Resolve all of the text rendering
  await Promise.all(pageList);

  // Map over the layers to mark any matched search text
  const marks = new Promise((resolve) => layers.map((layer) => {
    // Create the mark instance
    const mark = new Mark(layer);

    // Mark the text
    mark.mark(searchTerm, {
      separateWordSearch: false,
      done: () => {
        const list = layer.getElementsByTagName('mark');

        if (list[matchIndex]) {
          list[matchIndex].classList.add('highlighted');

          // Send the New Match Position
          resolve(parseFloat(list[matchIndex].parentElement.style.top));
        }

        // Default to resolve null
        resolve(null);
      }
    });
  }));

  // Get the new scroll position
  const scrollPosition = await marks;

  // Return the new state
  return { searchTerm, matches, scrollPosition, matchIndex };
});

export const showPage = async(params) => {
  // Get the first page
  const page = pdfDocuments[params.docId].pages[params.pageIndex];

  // Calculate the Viewport
  const viewport = page ? page.getViewport({ scale: params.scale }) : initialState.viewport;

  // Set the viewport
  pdfDocuments[params.docId].viewport = viewport;

  // Select the canvas element to draw
  const canvas = document.getElementById(`pdf-canvas-${params.docId}-${params.pageIndex}`);

  // Only Update the Canvas if it is present
  if (canvas) {
    // Update the Canvas
    canvas.height = viewport.height || PDF_PAGE_HEIGHT;
    canvas.width = viewport.width || PDF_PAGE_WIDTH;

    // Draw the PDF to the canvas
    await page.render({ canvasContext: canvas.getContext('2d', { alpha: false }), viewport }).promise;

    const text = await page.getTextContent();

    await PDF.renderTextLayer({
      container: document.getElementById(`text-${params.pageIndex}`),
      textContent: text,
      viewport,
      textDivs: []
    }).promise;
  }

  return { viewport };
};

/**
 * Dispatcher to show the selected PDF
 */
export const showPdf = createAsyncThunk('documentViewer/show', async ({
  rotation = null,
  pageNumber,
  currentDocument,
  worker,
  scale
}) => {
  // Attach the Service Worker if not already attached
  if (PDF.GlobalWorkerOptions.workerSrc !== worker) {
    PDF.GlobalWorkerOptions.workerSrc = worker;
  }
  // Request the PDF document from eFolder
  if (!pdfDocuments[currentDocument.id]) {
    const { body } = await ApiUtil.get(currentDocument.content_url, {
      cache: true,
      withCredentials: true,
      timeout: true,
      responseType: 'arraybuffer'
    });

    // Store the Document in-memory so that we do not serialize through Redux, but still persist
    pdfDocuments[currentDocument.id] = {
      pdf: await PDF.getDocument({ data: body }).promise
    };

    // Store the pages for the PDF
    pdfDocuments[currentDocument.id].pages = await Promise.all(
      range(0, pdfDocuments[currentDocument.id].pdf.numPages).map((pageIndex) =>
        pdfDocuments[currentDocument.id].pdf.getPage(pageIndex + 1))
    );
  }

  // Store the Viewport
  pdfDocuments[currentDocument.id].viewport = pdfDocuments[currentDocument.id].pages.reduce((viewport, page) => ({
    height: Math.max(viewport.height, page.getViewport({ scale }).height),
    width: Math.max(viewport.width, page.getViewport({ scale }).width)
  }), { height: 0, width: 0 });

  // Return the new Document state
  return {
    scale,
    viewport: pdfDocuments[currentDocument.id].viewport,
    currentDocument: {
      ...currentDocument,
      rotation: rotation === null ? 0 : (rotation + ROTATION_INCREMENTS) % COMPLETE_ROTATION,
      currentPage: parseInt(pageNumber, 10) || 1,
      numPages: pdfDocuments[currentDocument.id].pdf.numPages
    },
  };
});

/**
 * Dispatcher to Remove Tags from a Document
 */
export const removeTag = createAsyncThunk('documentViewer/removeTag', async({ doc, tag }) => {
  // Request the deletion of the selected tag
  await ApiUtil.delete(`/document/${doc.id}/tag/${tag.id}`, {}, ENDPOINT_NAMES.TAG);

  // Return the selected document and tag to the next Dispatcher
  return { doc, tag };
});

/**
 * Dispatcher to Add Tags for a Document
 */
export const addTag = createAsyncThunk('documentViewer/addTag', async({ doc, newTags }) => {
  // Request the addition of the selected tags
  const { body } = await ApiUtil.post(`/document/${doc.id}/tag`, { data: { tags: newTags } }, ENDPOINT_NAMES.TAG);

  // Return the selected document and tag to the next Dispatcher
  return { doc, newTags, ...body };
});

/**
 * Dispatcher to Save Description for a Document
 */
export const saveDescription = createAsyncThunk('documentViewer/saveDescription', async({ docId, description }) => {
  // Request the addition of the selected tags
  await ApiUtil.patch(`/document/${docId}`, { data: { description } });

  // Return the selected document and tag to the next Dispatcher
  return { description };
});

/**
 * Dispatcher to Remove Tags from a Document
 */
export const selectCurrentPdf = createAsyncThunk('documentViewer/selectCurrentPdf', async({ docId }) => {
  // Request the addition of the selected tags
  await ApiUtil.patch(`/document/${docId}/mark-as-read`, {}, ENDPOINT_NAMES.MARK_DOC_AS_READ);

  // Return the selected document and tag to the next Dispatcher
  return { docId };
});

/**
 * Dispatcher to Set the PDF as Opened
 */
export const selectCurrentPdfLocally = createAction('documentViewer/selectCurrentPdfLocally');

/**
 * Dispatcher to Set the PDF as Opened
 */
export const toggleDocumentCategoryFail = createAction('documentViewer/toggleDocumentCategoryFail');

/**
 * Dispatcher to Remove Tags from a Document
 */
export const handleCategoryToggle = createAsyncThunk('documentViewer/handleCategoryToggle', async({
  docId,
  categoryKey,
  toggleState
}) => {
  // Format the Category Key
  const category = formatCategoryName(categoryKey);

  // Request the addition of the selected tags
  await ApiUtil.patch(
    `/document/${docId}`,
    { data: { [category]: toggleState } },
    ENDPOINT_NAMES.DOCUMENT
  );

  // Return the selected document and tag to the next Dispatcher
  return { docId, category, toggleState };
});

/**
 * PDF Combined Reducer/Action creators
 */
const documentViewerSlice = createSlice({
  name: 'documentViewer',
  initialState,
  reducers: {
    toggleKeyboardInfo: (state, action) => {
      state.keyboardInfoOpen = action.payload;
    },
    setPageNumber: (state, action) => {
      state.selected.currentPage = action.payload;
    },
    changeDescription: (state, action) => {
      state.selected.pendingDescription = action.payload;
    },
    resetDescription: (state) => {
      state.selected.pendingDescription = null;
    },
    setOverscanValue: (state, action) => {
      state.windowingOverscan = action.payload;
    },
    toggleShareModal: (state, action) => {
      state.shareCommentId = action.payload;
    },
    toggleDeleteModal: (state, action) => {
      state.deleteCommentId = action.payload;
    },
    toggleAccordion: (state, action) => {
      state.openedAccordionSections = action.payload;
    },
    togglePdfSideBar: (state) => {
      state.hidePdfSidebar = !state.hidePdfSidebar;
    },
    toggleSearchBar: (state) => {
      state.hideSearchBar = !state.hideSearchBar;
    },
    updateSearchIndex: {
      reducer: (state, action) => {
        // Increment or Decrement the match index based on the payload
        state.matchIndex = action.payload.increment ?
          state.matchIndex + 1 :
          state.matchIndex - 1;
      },
      prepare: (increment) => ({ payload: { increment } })
    },
    setSearchIndex: {
      reducer: (state, action) => {
        // Update the Search Index
        state.matchIndex = action.payload.index;
      },
      prepare: (index) => ({ payload: { index } })
    },
    setSearchIndexToHighlight: {
      reducer: (state, action) => {
        // Update the Search Index
        state.search.matchIndex = action.payload.index;
      },
      prepare: (index) => ({ payload: { index } })
    },
    updateSearchIndexPage: {
      reducer: (state, action) => {
        // Update the Page Index
        state.pageIndexWithMatch = action.payload.index;
      },
      prepare: (index) => ({ payload: { index } })
    },
    updateSearchRelativeIndex: {
      reducer: (state, action) => {
        // Update the Relative Index
        state.relativeIndex = action.payload.index;
      },
      prepare: (index) => ({ payload: { index } })
    },
    setSearchIsLoading: {
      reducer: (state, action) => {
        // Update the Search Term
        state.search.searchIsLoading = action.payload.searchIsLoading;
      },
      prepare: (searchIsLoading) => ({ payload: { searchIsLoading } })
    },
    handleSelectCommentIcon: {
      reducer: (state, action) => {
        state.scrollToSidebarComment = action.payload.scrollToSidebarComment;
      },
      prepare: (comment) => ({ payload: { scrollToSidebarComment: comment } })
    },
    closeDocumentUpdatedModal: {
      reducer: (state, action) => {
        // Update the rotation of the document
        state.list[action.payload.docId].wasUpdated = false;
      },
      prepare: (docId) => ({ payload: { docId } })
    },
    handleToggleCommentOpened: {
      reducer: (state, action) => {
        // Update the rotation of the document
        state.list[action.payload.docId].listComments =
          !state.list[action.payload.docId].listComments;
      },
      prepare: (docId) =>
        addMetaLabel('toggle-comment-list', { docId }, (state) =>
          state.list[docId].listComments ? 'open' : 'close')
    },
  },
  extraReducers: (builder) => {
    builder.
      addCase(showPdf.pending, (state) => {
        state.loading = true;
      }).
      addCase(searchText.fulfilled, (state, action) => {
        // Update the Search Term
        state.search.searchTerm = action.payload.searchTerm;

        // Update the Total matches
        state.search.totalMatchesInFile = action.payload.matches;

        // Set the search index to 0
        state.search.matchIndex = action.payload.matchIndex || 0;

        state.search.scrollPosition = action.payload.scrollPosition;
      }).
      addCase(showPdf.fulfilled, (state, action) => {
        // Add the PDF data to the store
        state.selected = action.payload.currentDocument;

        // Add the PDF data to the store
        state.scale = action.payload.scale;
        state.viewport = action.payload.viewport;
      }).
      /* eslint-disable */
      addCase(selectCurrentPdf.rejected, (state, action) => {
        console.log('Error marking as read', action.payload.docId, action.payload.errorMessage);
      }).
      /* eslint-enable */
      addCase(saveDescription.fulfilled, (state, action) => {
        state.selected.pendingDescription = null;
        state.selected.description = action.payload.description;
      }).
      addCase(addTag.pending, {
        reducer: (state, action) => {
        // Set the tags that are being created
          state.list[action.payload.doc.id].tags.push(action.payload.newTags);
        },
        prepare: (doc, tags) => {
        // Calculate the new Tags
          const newTags = differenceWith(doc.tags, tags, (tag, currentTag) =>
            tag.value === currentTag.text).map((tag) => ({ text: tag.label, id: uuid.v4(), temporaryId: true }));

          // Return the formatted payload
          return {
            payload: {
              newTags,
              doc
            }
          };
        }
      }).
      addCase(addTag.fulfilled, (state, action) => {
        state.list[action.payload.doc.id].tags = state.list[action.payload.doc.id].tags.map((tag) => {
          // Locate the created tag
          const createdTag = find(action.payload.tags, pick(tag, 'text'));

          // If there is a created Tag, return that
          if (createdTag) {
            return createdTag;
          }

          // Default to return the original tag
          return tag;
        });
      }).
      addCase(addTag.rejected, (state, action) => {
      // Remove the tags that were attempted to be added
        state.list[action.payload.doc.id].tags =
        differenceBy(state.list[action.payload.doc.id].tags, action.payload.newTags, 'text');
      }).
      addCase(removeTag.pending, (state, action) => {
      // Set the pending Removal for the selected tag to true
        state.list[action.payload.doc.id].tags[action.payload.tag.id].pendingRemoval = true;
      }).
      addCase(removeTag.fulfilled, (state, action) => {
      // Remove the tag from the list
        delete state.list[action.payload.doc.id].tags[action.payload.tag.id];
      }).
      addCase(removeTag.rejected, (state, action) => {
        // Reset the pending Removal for the selected tag to false
        state.list[action.payload.doc.id].tags[action.payload.tag.id].pendingRemoval = false;
      }).
      addCase(handleCategoryToggle.fulfilled, (state, action) => {
        // Apply the Category toggle
        state.selected[action.payload.category] = action.payload.toggleState;
      }).
      addMatcher(
        (action) => [
          selectCurrentPdf.fulfilled.toString(),
          selectCurrentPdfLocally.toString()
        ].includes(action.type),
        (state, action) => {
          state.list[action.payload.docId].opened_by_current_user = true;
        }
      ).
      addMatcher(
        (action) => action.type === removeComment.fulfilled.toString(),
        (state) => {
        // Remove the modal state
          state.deleteCommentId = null;
        }
      );
  }
});

// Export the Reducer actions
export const {
  changePendingDocDescription,
  resetPendingDocDescription,
  rotateDocument,
  closeDocumentUpdatedModal,
  handleToggleCommentOpened,
  handleSelectCommentIcon,
  onScrollToComment,
  setZoomLevel,
  togglePdfSideBar,
  toggleSearchBar,
  toggleAccordion,
  toggleDeleteModal,
  toggleShareModal,
  setOverscanValue,
  changeDescription,
  resetDescription,
  setPageNumber,
  toggleKeyboardInfo
} = documentViewerSlice.actions;

// Default export the reducer
export default documentViewerSlice.reducer;

