import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import * as PDF from 'pdfjs';
import ApiUtil from 'app/util/ApiUtil';

/**
 * PDF Initial State
 */
export const initialState = {
  hideSearchBar: true,
  hidePdfSidebar: false,
  scrollToComment: null,
  pageDimensions: {},
  pdfDocuments: {},
  documentErrors: {},
  text: [],
  currentDocument: {},
  loading: false
};

export const showPage = createAsyncThunk('pdf/changePage', async(params) => {
  // Convert the Array Buffer to a PDF
  const pdf = await PDF.getDocument({ data: params.data }).promise;

  console.log('PDF INFO: ', pdf.numPages);

  // Get the first page
  const page = await pdf.getPage(1);

  console.log('PAGE: ', page);

  // Select the canvas element to draw
  const canvas = document.getElementById('pdf-canvas');

  // Draw the PDF to the canvas
  await page.render({
    canvasContext: canvas.getContext('2d', { alpha: false }),
    viewport: page.getViewport(params.scale)
  }).promise;

  // Update the store with the PDF Pages
  return {
    docId: params.docId,
    numPages: pdf.numPages
  };
});

/**
 * Dispatcher to show the selected PDF
 */
export const showPdf = createAsyncThunk('pdf/show', async ({
  current,
  documents,
  docId,
  worker,
  scale
}, { dispatch }) => {
  // Attach the Service Worker if not already attached
  if (PDF.GlobalWorkerOptions.workerSrc !== worker) {
    PDF.GlobalWorkerOptions.workerSrc = worker;
  }

  // Get the Selected Document
  const [currentDocument] = documents.filter((doc) => doc.id.toString() === docId);

  // Request the Document if it is not loaded
  if (current.id !== currentDocument.id) {
  // Request the PDF document from eFolder
    const { body } = await ApiUtil.get(currentDocument.content_url, {
      cache: true,
      withCredentials: true,
      timeout: true,
      responseType: 'arraybuffer'
    });

    // Set the Page
    dispatch(showPage({ scale, data: body, docId: currentDocument.id }));
  }

  // Return the Document Buffer
  return { currentDocument };
});

/**
 * PDF Combined Reducer/Action creators
 */
const pdfSlice = createSlice({
  name: 'pdf',
  initialState,
  reducers: {
    onScrollToComment: (state, action) => {
      state.scrollToComment = action.payload.scrollToComment;
    },
    setPageDimensions: {
      reducer: (state, action) => {
        state.pageDimensions[action.payload.file] = action.payload.dimensions;
      },
      prepare: (file, dimensions) => ({ payload: { file, dimensions } })
    },
    setPdfDocument: {
      reducer: (state, action) => {
        state.pdfDocuments[action.payload.file] = action.payload.doc;
      },
      prepare: (file, doc) => ({ payload: { file, doc } })
    },
    clearPdfDocument: {
      reducer: (state, action) => {
        if (action.payload.doc && state.pdfDocuments[action.payload.file] === action.payload.doc) {
          state.pdfDocuments[action.payload.file] = null;
        }
      },
      prepare: (file, pageIndex, doc) => ({ payload: { file, pageIndex, doc } })
    },
    setDocumentLoadError: {
      reducer: (state, action) => {
        state.documentErrors[action.payload.file] = true;
      },
      prepare: (file) => ({ payload: { file } })
    },
    clearDocumentLoadError: {
      reducer: (state, action) => {
        state.documentErrors[action.payload.file] = false;
      },
      prepare: (file) => ({ payload: { file } })
    }
  },
  extraReducers: (builder) => {
    builder.
      addCase(showPdf.pending, (state) => {
        state.loading = true;
      }).
      addCase(showPage.fulfilled, (state, action) => {
        // Add the PDF data to the store
        state.pdfDocuments[action.payload.docId] = {
          numPages: action.payload.numPages,
        };
      });
  }
});

// Export the Reducer actions
export const {
  onScrollToComment,
  setPageDimensions,
  setPdfDocument,
  clearPdfDocument,
  setDocumentLoadError,
  clearDocumentLoadError,
} = pdfSlice.actions;

// Default export the reducer
export default pdfSlice.reducer;
