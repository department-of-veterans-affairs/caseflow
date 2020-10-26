import { createSlice } from '@reduxjs/toolkit';

/**
 * PDF Initial State
 */
export const initialState = {
  scrollToComment: null,
  pageDimensions: {},
  pdfDocuments: {},
  documentErrors: {},
  text: []
};

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
  }
});

// Export the Reducer actions
export const {
  onScrollToComment,
  setPageDimensions,
  setPdfDocument,
  clearPdfDocument,
  setDocumentLoadError,
  clearDocumentLoadError
} = pdfSlice.actions;

// Default export the reducer
export default pdfSlice.reducer;
