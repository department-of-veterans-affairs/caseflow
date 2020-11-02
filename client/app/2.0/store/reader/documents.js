import { createSlice, createAction, createAsyncThunk, current } from '@reduxjs/toolkit';
import { isNil, differenceWith, differenceBy, find, pick } from 'lodash';
import uuid from 'uuid';

// Local Dependencies
import ApiUtil from 'app/util/ApiUtil';
import { ENDPOINT_NAMES, ROTATION_INCREMENTS, COMPLETE_ROTATION } from 'store/constants/reader';
import {
  changeSortState,
  clearCategoryFilters,
  setCategoryFilter,
  setTagFilter,
  clearTagFilters,
  setSearch,
  clearSearch,
  clearAllFilters
} from 'store/reader/documentList';
import { addMetaLabel, commentContainsWords, formatCategoryName } from 'utils/reader';

/**
 * PDF Initial State
 */
export const initialState = {
  loading: false,
  list: {}
};

/**
 * Dispatcher to Load Appeal Documents
 */
export const loadDocuments = createAsyncThunk('documents/load', async (vacolsId, { getState }) => {
  // Get the current state
  const state = getState();

  // Request the Documents for the Appeal
  const { body } = await ApiUtil.get(`/reader/appeal/${vacolsId}/documents?json`, {}, ENDPOINT_NAMES.DOCUMENTS);

  // Return the response and attach the Filter Criteria
  return { ...body, vacolsId, docFilterCriteria: state.reader.documentList.docFilterCriteria };
});

/**
 * Dispatcher to Remove Tags from a Document
 */
export const removeTag = createAsyncThunk('documents/removeTag', async({ doc, tag }) => {
  // Request the deletion of the selected tag
  await ApiUtil.delete(`/document/${doc.id}/tag/${tag.id}`, {}, ENDPOINT_NAMES.TAG);

  // Return the selected document and tag to the next Dispatcher
  return { doc, tag };
});

/**
 * Dispatcher to Add Tags for a Document
 */
export const addTag = createAsyncThunk('documents/addTag', async({ doc, newTags }) => {
  // Request the addition of the selected tags
  const { body } = await ApiUtil.post(`/document/${doc.id}/tag`, { data: { tags: newTags } }, ENDPOINT_NAMES.TAG);

  // Return the selected document and tag to the next Dispatcher
  return { doc, newTags, ...body };
});

/**
 * Dispatcher to Save Description for a Document
 */
export const saveDocumentDescription = createAsyncThunk('documents/saveDescription', async({ docId, description }) => {
  // Request the addition of the selected tags
  await ApiUtil.patch(`/document/${docId}`, { data: { description } });

  // Return the selected document and tag to the next Dispatcher
  return { docId, description };
});

/**
 * Dispatcher to Remove Tags from a Document
 */
export const selectCurrentPdf = createAsyncThunk('documents/saveDescription', async({ docId }) => {
  // Request the addition of the selected tags
  await ApiUtil.patch(`/document/${docId}/mark-as-read`, {}, ENDPOINT_NAMES.MARK_DOC_AS_READ);

  // Return the selected document and tag to the next Dispatcher
  return { docId };
});

/**
 * Dispatcher to Set the PDF as Opened
 */
export const selectCurrentPdfLocally = createAction('documents/selectCurrentPdfLocally');

/**
 * Dispatcher to Set the PDF as Opened
 */
export const toggleDocumentCategoryFail = createAction('documents/toggleDocumentCategoryFail');

/**
 * Dispatcher to Remove Tags from a Document
 */
export const handleCategoryToggle = createAsyncThunk('documents/handleCategoryToggle', async({
  docId,
  categoryKey,
  toggleState
}) => {
  // Request the addition of the selected tags
  await ApiUtil.patch(
    `/document/${docId}`,
    { data: { [categoryKey]: toggleState } },
    ENDPOINT_NAMES.DOCUMENT
  );

  // Return the selected document and tag to the next Dispatcher
  return { docId };
});

/**
 * PDF Combined Reducer/Action creators
 */
const documentsSlice = createSlice({
  name: 'documents',
  initialState,
  reducers: {
    changePendingDocDescription: {
      reducer: (state, action) => {
        state.list[action.payload.docId].pendingDescription = action.payload.description;
      },
      prepare: (docId, description) => ({ payload: { docId, description } })
    },
    resetPendingDocDescription: {
      reducer: (state, action) => {
        delete state.list[action.payload.docId].pendingDescription;
      },
      prepare: (docId, description) => ({ payload: { docId, description } })
    },
    rotateDocument: {
      reducer: (state, action) => {
        // Calculate the rotation Based on the Rotation Increments
        const rotation =
         (state.list[action.payload.docId].rotation + ROTATION_INCREMENTS) % COMPLETE_ROTATION;

        // Update the rotation of the document
        state.list[action.payload.docId].rotation = rotation;
      },
      prepare: (docId) => ({ payload: { docId } })
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
      addCase(loadDocuments.pending, (state) => {
        state.loading = true;
      }).
      /* eslint-disable */
      addCase(selectCurrentPdf.rejected, (state, action) => {
        console.log('Error marking as read', action.payload.docId, action.payload.errorMessage);
      }).
      /* eslint-enable */
      addCase(saveDocumentDescription.fulfilled, (state, action) => {
        state.list[action.payload.doc.id].description = action.payload.description;
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
      addCase(loadDocuments.fulfilled, (state, action) => {
        state.list = action.payload.appealDocuments.reduce((list, doc) => ({
          ...list,
          [doc.id]: {
            ...doc,
            receivedAt: doc.received_at,
            listComments: false,
            wasUpdated: !isNil(doc.previous_document_version_id) && !doc.opened_by_current_user
          }
        }), {});
      }).
      addCase(handleCategoryToggle.fulfilled, {
        reducer: (state, action) => {
          state.list[action.payload.docId][action.payload.categoryKey] = action.payload.toggleState;
        },
        prepare: (payload) =>
          addMetaLabel(`${payload.toggleState ? 'set' : 'unset'} document category`, payload, payload.categoryName)
      }).
      addCase(handleCategoryToggle.pending, {
        prepare: (docId, categoryName, toggleState) => {
          const categoryKey = formatCategoryName(categoryName);

          return {
            payload: {
              docId,
              categoryKey,
              toggleState
            }
          };
        }
      }).
      addMatcher(
        (action) => [
          loadDocuments.fulfilled.toString(),
          loadDocuments.rejected.toString()
        ].includes(action.type),
        (state) => {
          // Reset the Loading State
          state.loading = false;
        }).
      addMatcher(
        (action) => [
          toggleDocumentCategoryFail.toString(),
          handleCategoryToggle.rejected.toString()
        ].includes(action.type),
        (state, action) => {
          state.list[action.payload.docId][action.payload.categoryKey] = !action.payload.toggleState;
        }
      ).
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
        (action) => [
          changeSortState.toString(),
          clearCategoryFilters.toString(),
          setCategoryFilter.toString(),
          setTagFilter.toString(),
          clearTagFilters.toString(),
          setSearch.toString(),
          clearSearch.toString(),
          clearAllFilters.toString(),
          loadDocuments.fulfilled.toString()
        ].includes(action.type), (state, { payload, ...action }) => {
          // Format the search query
          const searchQuery = action.type === clearSearch.toString() ?
            '' :
            payload.docFilterCriteria.searchQuery.toLowerCase();

          // Loop through all the documents to update the list comments
          Object.keys(state.list).forEach((docId) => {
            // Get the Document
            const doc = state.list[docId];

            // Determine whether the comment contains the search query
            const containsWords = commentContainsWords(searchQuery, payload, doc);

            // Updating the state of all annotations for expanded comments
            if (containsWords !== doc.listComments) {
              state.list[doc.id].listComments = containsWords;
            }
          });
        });
  }
});

// Export the Reducer actions
export const {
  changePendingDocDescription,
  resetPendingDocDescription,
  rotateDocument,
  closeDocumentUpdatedModal,
  handleToggleCommentOpened
} = documentsSlice.actions;

// Default export the reducer
export default documentsSlice.reducer;

