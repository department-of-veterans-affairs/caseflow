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

export const showPage = createAsyncThunk('pdf/changePage', async(data) => {
  // Convert the Array Buffer to a PDF
  const pdf = await PDF.getDocument({ data }).promise;

  // Get the first page
  const page = await pdf.getPage(1);

  console.log('PAGE: ', page);

  // Select the canvas element to draw
  // const canvas = document.getElementById('pdf-canvas');

  // console.log('CANVAS: ', canvas);

  // Draw the PDF to the canvas
});

/**
 * Dispatcher to show the selected PDF
 */
export const showPdf = createAsyncThunk('pdf/show', async ({ current, documents, docId, worker }, { dispatch }) => {
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
    dispatch(showPage(body));
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
