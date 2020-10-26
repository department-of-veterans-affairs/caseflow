import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { range } from 'lodash';

/**
 * PDF Initial State
 */
export const initialState = {
  matchIndex: 0,
  indexToHighlight: null,
  relativeIndex: 0,
  pageIndexWithMatch: null,
  extractedText: {},
  searchIsLoading: false
};

/**
 * Method for Extracting text from PDF Documents
 */
export const getDocumentText = createAsyncThunk('pdfSearch/documentText', async ({ pdfDocument, file }) => {
  // Create a function to extract text
  const extractText = (index) => pdfDocument.getPage(index + 1).then((page) => page.getTextContent());

  // Map the Extract to promises
  const textPromises = range(pdfDocument.pdfInfo.numPages).map((index) => extractText(index));

  // Wait for the search to complete
  const pages = await Promise.all(textPromises);

  // Reduce the Pages to an object containing the matches
  return pages.
    reduce((acc, page, pageIndex) => ({
      ...acc,
      [`${file}-${pageIndex}`]: {
        id: `${file}-${pageIndex}`,
        file,
        text: page.items.map((row) => row.str).join(' '),
        pageIndex
      }
    }),
    {});
});

/**
 * PDF Combined Reducer/Action creators
 */
const pdfSearchSlice = createSlice({
  name: 'pdfSearch',
  initialState,
  reducers: {
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
        state.matchIndex = action.payload.index;
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
    searchText: {
      reducer: (state, action) => {
        // Update the Search Term
        state.searchTerm = action.payload.searchTerm;

        // Set the search index to 0
        state.matchIndex = 0;
      },
      prepare: (searchTerm) => ({ payload: { searchTerm } })
    },
    setSearchIsLoading: {
      reducer: (state, action) => {
        // Update the Search Term
        state.searchIsLoading = action.payload.searchIsLoading;
      },
      prepare: (searchIsLoading) => ({ payload: { searchIsLoading } })
    }
  },
  extraReducers: (builder) => {
    builder.
      addCase(getDocumentText.fulfilled, (state, action) => {
        state.extractedText = action.payload;
      });
  }
});

// Export the Reducer actions
export const {
  updateSearchIndex,
  setSearchIndex,
  setSearchIndexToHighlight,
  updateSearchIndexPage,
  updateSearchRelativeIndex,
  searchText,
  setSearchIsLoading
} = pdfSearchSlice.actions;

// Default export the reducer
export default pdfSearchSlice.reducer;
