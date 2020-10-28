// External Dependencies
import { createSlice, createAsyncThunk, current } from '@reduxjs/toolkit';

// Local Dependencies
import { addMetaLabel } from 'utils/reader';
import { ENDPOINT_NAMES } from 'store/constants/reader';
import ApiUtil from 'app/util/ApiUtil';
import { loadDocuments } from 'store/reader/documents';

/**
 * Case Select Initial State
 */
export const initialState = {
  selectedAppealVacolsId: null,
  isRequestingAppealsUsingVeteranId: false,
  selectedAppeal: {},
  receivedAppeals: [],
  search: {
    showErrorMessage: false,
    noAppealsFoundSearchQueryValue: null
  },
  caseSelectCriteria: {
    searchQuery: ''
  },
  assignments: [],
  assignmentsLoaded: false
};

/**
 * Delete Annotation dispatcher
 * NOTE: This dispatcher is async so we export separately
 */
export const fetchAppealUsingVeteranId = createAsyncThunk('appeal/fetchByVeteranId', async ({ veteranId }) => {
  // Fetch the Appeal by Veteran ID
  const { body } = await ApiUtil.get(
    '/reader/appeal/veteran-id?json',
    {
      headers: { 'veteran-id': veteranId }
    },
    ENDPOINT_NAMES.APPEAL_DETAILS_BY_VET_ID
  );

  // Return the Annotation ID
  return {
    ...body,
    veteranId
  };
});

/**
 * Case Select Combined Reducer/Action creators
 */
const caseSelectSlice = createSlice({
  name: 'caseSelect',
  initialState,
  reducers: {
    clearCaseSelectSearch: (state) => ({
      ...state,
      caseSelectCriteria: {
        searchQuery: ''
      },
      receivedAppeals: [],
      selectedAppeal: {},
      selectedAppealVacolsId: null,
      search: {
        showErrorMessage: false,
        noAppealsFoundSearchQueryValue: null
      }
    }),
    setCaseSelectSearch: {
      reducer: (state, action) => {
        state.caseSelectCriteria.searchQuery = action.payload.searchQuery;
      },
      prepare: (searchQuery) => ({ payload: { searchQuery } })
    },
    caseSelectAppeal: {
      reducer: (state, action) => {
        state.selectedAppeal = action.payload.appeal;
      },
      prepare: (appeal) => ({ payload: { appeal } })
    },
    caseSelectModalSelectVacolsId: {
      reducer: (state, action) => {
        state.selectedAppealVacolsId = action.payload.vacolsId;
      },
      prepare: (vacolsId) => ({ payload: { vacolsId } })
    },
    setViewedAssignment: {
      reducer: (state, action) => {
        state.assignments = state.assignments.map((assignment) => ({
          ...assignment,
          viewed: assignment.vacols_id === action.payload.vacolsId || assignment.viewed
        }));
      },
      prepare: (vacolsId) => ({ payload: { vacolsId } })
    },
    onReceiveAssignments: {
      reducer: (state, action) => {
        // Set the Assignments
        state.assignments = action.payload.assignments;

        // Update the status of assignments
        state.assignmentsLoaded = true;
      },
      prepare: (assignments) => ({ payload: { assignments } })
    },
  },
  extraReducers: (builder) => {
    builder.
      addCase(loadDocuments.fulfilled, (state, action) => {
        state.assignments = state.assignments.map((assignment) => ({
          ...assignment,
          viewed: assignment.vacols_id === action.payload.vacolsId || assignment.viewed
        }));
      }).
      addCase(fetchAppealUsingVeteranId.pending, {
        reducer: (state) => {
          state.isRequestingAppealsUsingVeteranId = true;
        },
        prepare: (vacolsId) => addMetaLabel('case-search', { vacolsId })
      }).
      addCase(fetchAppealUsingVeteranId.fulfilled, (state, action) => {
        if (action.payload.appeals.length === 0) {
          state.isRequestingAppealsUsingVeteranId = false;
          state.search.showErrorMessage = false;
          state.noAppealsFoundSearchQueryValue = action.payload.searchQuery;
        } else {
          // Set the Received Appeals
          state.receivedAppeals = action.payload.appeals;

          // Remove the requesting state
          state.isRequestingAppealsUsingVeteranId = false;
          state.search.showErrorMessage = false;
          state.noAppealsFoundSearchQueryValue = null;
        }
      }).
      addCase(fetchAppealUsingVeteranId.rejected, (state) => {
        state.isRequestingAppealsUsingVeteranId = false;
        state.search.showErrorMessage = true;
        state.noAppealsFoundSearchQueryValue = null;
      });
  }
});

// Export the Reducer actions
export const {
  clearCaseSelectSearch,
  setCaseSelectSearch,
  caseSelectAppeal,
  caseSelectModalSelectVacolsId,
  setViewedAssignment,
  onReceiveAssignments
} = caseSelectSlice.actions;

// Default export the reducer
export default caseSelectSlice.reducer;
