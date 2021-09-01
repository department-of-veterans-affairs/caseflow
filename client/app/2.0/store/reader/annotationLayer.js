// External Dependencies
import { isEmpty } from 'lodash';
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

// Local Dependencies
import { loadDocuments } from 'store/reader/documentList';
import { addMetaLabel } from 'utils/reader';
import { ENDPOINT_NAMES } from 'store/constants/reader';
import ApiUtil from 'app/util/ApiUtil';

// Extract the Annotation Endpoint
const { ANNOTATION } = ENDPOINT_NAMES;

/**
 * Annotation Layer Initial State
 */
export const initialState = {
  comments: [],
  selected: {},
  errors: {},
  saving: false,
  dropping: false,
  moving: 0,
  droppedComment: null,
  pendingDeletion: false,
  editingComment: false,
};

/**
 * Delete Annotation dispatcher
 * NOTE: This dispatcher is async so we export separately
 */
export const removeComment = createAsyncThunk('annotations/delete', async ({ docId, commentId }) => {
  // Send the Delete Request
  await ApiUtil.delete(`/document/${docId}/annotation/${commentId}`, {}, ANNOTATION);

  // Return the Annotation ID
  return commentId;
});

/**
 * Move Annotation Dispatcher
 * NOTE: This dispatcher is async so we export separately
 */
export const moveComment = createAsyncThunk('annotations/move', async (annotation) => {
  // Format the data to send to the API
  const data = ApiUtil.convertToSnakeCase({ annotation });

  // Don't update the temporary comment
  if (annotation.id !== 'placing-annotation-icon') {
  // Patch the Selected Annotation
    await ApiUtil.patch(`/document/${annotation.document_id}/annotation/${annotation.id}`, { data }, ANNOTATION);

  }

  return annotation;
});

/**
 * Edit Annotation Dispatcher
 * NOTE: This dispatcher is async so we export separately
 */
export const saveComment = createAsyncThunk('annotations/save', async (annotation) => {
  // If the user removed all text content in the annotation (or if only whitespace characters remain),
  // ask the user if they're intending to delete it.
  if (!annotation.comment.trim()) {
    return;
  }

  // Format the data to send to the API
  const data = ApiUtil.convertToSnakeCase({ annotation });

  // Patch the Selected Annotation
  await ApiUtil.patch(`/document/${annotation.document_id}/annotation/${annotation.id}`, { data }, ANNOTATION);

  // Return the Annotation to update the state
  return annotation;
});

/**
 * Create Annotation Dispatcher
 * NOTE: This dispatcher is async so we export separately
 */
export const createComment = createAsyncThunk('annotations/create', async (annotation) => {
  // Format the data to send to the API
  const data = ApiUtil.convertToSnakeCase({ annotation });

  // Patch the Selected Annotation
  const { body } = await ApiUtil.post(`/document/${annotation.document_id}/annotation`, { data }, ANNOTATION);

  // Add the request body to the annotation
  return {
    ...annotation,
    ...body,
  };
});

/**
 * Annotation Layer Combined Reducer/Action creators
 */
const annotationLayerSlice = createSlice({
  name: 'annotationLayer',
  initialState,
  reducers: {
    [removeComment.fulfilled.toString()]: {
      prepare: (commentId) => {
        return addMetaLabel('request-delete-annotation', commentId);
      }
    },
    startMove: {
      reducer: (state, action) => {
        state.moving = action.payload;
      },
      prepare: (moving) => addMetaLabel('request-move-annotation', moving)
    },
    addComment: {
      reducer: (state) => {
        state.dropping = true;
      },
      prepare: () => addMetaLabel('start-placing-annotation')
    },
    dropComment: {
      reducer: (state, action) => {
      // Reset the dropping state
        state.dropping = false;

        // Set the dropped comment
        state.droppedComment = action.payload;

        // Update the comments with the temporary comment
        state.comments = [...state.comments, action.payload];
      },
      prepare: (droppedComment) => addMetaLabel('stop-placing-annotation', droppedComment)
    },
    cancelDrop: {
      reducer: (state) => {
      // Reset the dropping state
        state.dropping = false;

        // Update the comments with the temporary comment
        state.comments = state.comments.filter((comment) => comment.id !== 'placing-annotation-icon');

        // Remove the dropped comment
        state.droppedComment = null;

        // Remove the error state
        state.errors = initialState.errors;
      },
      prepare: () => addMetaLabel('cancel-placing-annotation')
    },
    startEdit: {
      reducer: (state, action) => {
        state.comments = state.comments.map((comment) => ({
          ...comment,
          pendingComment: comment.comment,
          editing: comment.id === action.payload
        }));

        // Update the selected comment
        state.selected = state.comments.filter((comment) => comment.id === action.payload)[0];
      },
      prepare: (commentId) => addMetaLabel('start-edit-annotation', commentId)
    },
    updateComment: {
      reducer: (state, action) => {
        // Update the state of the dropped comment otherwise update the selected comment
        if (state.droppedComment) {
          state.droppedComment = {
            ...state.droppedComment,
            pendingComment: action.payload.pendingComment,
            pendingDate: action.payload.pendingDate
          };
        } else {
          state.selected = {
            ...state.selected,
            pendingComment: action.payload.pendingComment,
            pendingDate: action.payload.pendingDate
          };
        }

        state.comments = state.comments.map((comment) => ({
          ...comment,
          pendingDate: comment.id === action.payload.id ? action.payload.pendingDate : null,
          pendingComment: comment.id === action.payload.id ? action.payload.pendingComment : null
        }));
      },
      prepare: (payload) => {
        if (isEmpty(payload)) {
          addMetaLabel('cancel-edit-annotation', payload);
        } else {
          addMetaLabel('edit-annotation-content-locally', payload);
        }
      }
    },
    selectComment: {
      reducer: (state, action) => {
        state.selected = action.payload.comment;
      },
      prepare: (comment) => addMetaLabel('select-annotation', { comment })
    },
  },
  extraReducers: (builder) => {
    builder.
      addCase(saveComment.rejected, (state, action) => {
        // Reset the save state
        state.saving = false;

        // Update the error messages
        state.errors.comment = {
          ...action.error,
          visible: true
        };
      }).
      addCase(saveComment.pending, (state) => {
        state.saving = true;
      }).
      addCase(saveComment.fulfilled, (state, action) => {
        // Reset the state
        state.saving = false;
        state.editingComment = false;
        state.droppedComment = null;

        // Update the comment state
        state.comments = [
          ...state.comments.filter((comment) => !comment.editing),
          {
            ...action.payload,
            editing: null
          }
        ];
      }).
      addCase(createComment.pending, (state) => {
        state.saving = true;
      }).
      addCase(createComment.fulfilled, (state, action) => {
        // Reset the state
        state.saving = false;
        state.droppedComment = null;

        // Update the comments list
        state.comments = [
          ...state.comments.filter((comment) => comment.id !== 'placing-annotation-icon'),
          action.payload
        ];
      }).
      addCase(createComment.rejected, (state, action) => {
        // Reset the save state
        state.saving = false;

        // Update the error messages
        state.errors.comment = {
          ...action.error,
          visible: true
        };
      }).
      addCase(moveComment.fulfilled, (state, action) => {
        // Reset the moving state
        state.moving = 0;

        // Update the comments list
        state.comments = state.comments.map((comment) => ({
          ...comment,
          ...(comment.id === action.payload.id ? action.payload : {})
        }));
      }).
      addCase(moveComment.rejected, (state, action) => {
        // Update the error messages
        state.errors.comment = {
          ...action.error,
          visible: true
        };

        // Reset the moving state
        state.moving = false;
      }).
      addCase(removeComment.pending, (state) => {
        // Set the pending deletion to disable the modal buttons
        state.pendingDeletion = true;
      }).
      addCase(removeComment.fulfilled, (state, action) => {
        // Reset the state
        state.pendingDeletion = false;

        // Update the comments list
        state.comments = state.comments.filter((comment) => comment.id !== action.payload);
      }).
      addCase(removeComment.rejected, (state) => {
        // Reset the state
        state.pendingDeletion = false;
      }).
      addMatcher((action) => action.type === loadDocuments.fulfilled.toString(), (state, action) => {
        // Map the Annotations to the comments array
        state.comments = action.payload.annotations;
      });
  }
});

// Export the Reducer actions
export const {
  selectComment,
  startEdit,
  updateComment,
  addComment,
  dropComment,
  cancelDrop,
  startMove
} = annotationLayerSlice.actions;

// Default export the reducer
export default annotationLayerSlice.reducer;
