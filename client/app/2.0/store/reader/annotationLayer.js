// External Dependencies
import { createSlice, createAsyncThunk, current } from '@reduxjs/toolkit';
import { keyBy } from 'lodash';

// Local Dependencies
import { loadDocuments } from 'store/reader/documentList';
import { setPageNumber } from 'store/reader/documentViewer';
import { addMetaLabel } from 'utils/reader';
import { ENDPOINT_NAMES } from 'store/constants/reader';
import ApiUtil from 'app/util/ApiUtil';

/**
 * Annotation Layer Initial State
 */
export const initialState = {
  comments: [],
  selected: {},
  errors: {},
  placingAnnotationIconPageCoords: null,
  pendingAnnotations: {},
  pendingEditingAnnotations: {},
  selectedAnnotationId: null,
  deleteAnnotationModalIsOpenFor: null,
  shareAnnotationModalIsOpenFor: null,
  placedButUnsavedAnnotation: null,
  isPlacingAnnotation: false,
  saving: false,
  dropping: false,
  moving: 0,
  droppedComment: null,
  pendingDeletion: false,

  /**
   * `editingAnnotations` is an object of annotations that are currently being edited.
   * When a user starts editing an annotation, we copy it from `annotations` to `editingAnnotations`.
   * To commit the edits, we copy from `editingAnnotations` back into `annotations`.
   * To discard the edits, we delete from `editingAnnotations`.
   */
  editingAnnotations: {}
};

/**
 * Method to change the Annotation ID within the Redux Store
 * @param {Object} state -- The store state that we are changing
 * @param {Object} action -- Contains the payload with the new Annotation ID
 */
export const toggleAnnotationDeleteModal = (state, annotationId) => {
  state.deleteAnnotationModalIsOpenFor = annotationId;
};

/**
 * Method to toggle whether the Annotation Share Modal is open
 * @param {Object} state -- The current Redux store state
 * @param {string} annotationId -- The ID of the annotation to show/hide the share modal
 */
export const toggleAnnotationShareModal = (state, annotationId) => {
  state.shareAnnotationModalIsOpenFor = annotationId;
};

/**
 * Delete Annotation dispatcher
 * NOTE: This dispatcher is async so we export separately
 */
export const removeComment = createAsyncThunk('annotations/delete', async ({ docId, commentId }) => {
  // Send the Delete Request
  await ApiUtil.delete(`/document/${docId}/annotation/${commentId}`, {}, ENDPOINT_NAMES.ANNOTATION);

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
    await ApiUtil.patch(
    `/document/${annotation.document_id}/annotation/${annotation.id}`,
    { data },
    ENDPOINT_NAMES.ANNOTATION
    );

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
  await ApiUtil.patch(
    `/document/${annotation.document_id}/annotation/${annotation.id}`,
    { data },
    ENDPOINT_NAMES.ANNOTATION
  );

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
  const { body } = await ApiUtil.post(
    `/document/${annotation.document_id}/annotation`,
    { data },
    ENDPOINT_NAMES.ANNOTATION
  );

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
    startMove: (state, action) => {
      state.moving = action.payload;
    },
    addComment: (state) => {
      state.dropping = true;
    },
    dropComment: (state, action) => {
      // Reset the dropping state
      state.dropping = false;

      // Set the dropped comment
      state.droppedComment = action.payload;

      // Update the comments with the temporary comment
      state.comments = [...state.comments, action.payload];
    },
    cancelDrop: (state) => {
      // Reset the dropping state
      state.dropping = false;

      // Update the comments with the temporary comment
      state.comments = state.comments.filter((comment) => comment.id !== 'placing-annotation-icon');

      // Remove the dropped comment
      state.droppedComment = null;

      // Remove the error state
      state.errors = initialState.errors;
    },
    startEdit: (state, action) => {
      state.comments = state.comments.map((comment) => ({
        ...comment,
        editing: comment.id === action.payload
      }));
    },
    updateComment: (state, action) => {
      if (state.droppedComment) {
        state.droppedComment = {
          ...state.droppedComment,
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
    openAnnotationDeleteModal: {
      reducer: (state, action) => toggleAnnotationDeleteModal(state, action.payload.annotationId),
      prepare: (annotationId, label) => addMetaLabel('open-annotation-delete-modal', { annotationId }, label)
    },
    closeAnnotationDeleteModal: {
      reducer: (state) => toggleAnnotationDeleteModal(state, null),
      prepare: (includeMetrics = true) => addMetaLabel('close-annotation-delete-modal', null, '', includeMetrics)
    },
    openAnnotationShareModal: {
      reducer: (state, action) => toggleAnnotationShareModal(state, action.payload.annotationId),
      prepare: (annotationId, label) => addMetaLabel('open-annotation-share-modal', { annotationId }, label)
    },
    closeAnnotationShareModal: {
      reducer: (state) => toggleAnnotationShareModal(state, null),
      prepare: (includeMetrics = true) => addMetaLabel('close-annotation-share-modal', null, '', includeMetrics)
    },
    selectComment: {
      reducer: (state, action) => {
        state.selected = action.payload.comment;
      },
      prepare: (comment) => addMetaLabel('select-annotation', { comment })
    },
    startPlacingAnnotation: {
      reducer: (state) => {
        state.isPlacingAnnotation = true;
      },
      prepare: (interactionType) => addMetaLabel('start-placing-annotation', null, interactionType)
    },
    stopPlacingAnnotation: {
      reducer: (state) => {
        state.placingAnnotationIconPageCoords = null;
        state.placedButUnsavedAnnotation = null;
        state.isPlacingAnnotation = false;
      },
      prepare: (interactionType) => addMetaLabel('stop-placing-annotation', null, interactionType)
    },
    onReceiveAnnotations: (state, action) => {
      state.annotations = keyBy(
        action.payload.annotations.map((annotation) => ({
          ...annotation,
          documentId: annotation.document_id,
          uuid: annotation.id
        })),
        'id'
      );
    },
    placeAnnotation: {
      reducer: (state, action) => {
        state.placedButUnsavedAnnotation = {
          ...action.payload,
          class: 'Annotation',
          type: 'point'
        };
        state.isPlacingAnnotation = false;
      },
      prepare: (pageNumber, coordinates, documentId) => ({
        payload: {
          page: pageNumber,
          x: coordinates.xPosition,
          y: coordinates.yPosition,
          documentId
        }
      })
    },
    showPlaceAnnotationIcon: (state, action) => {
      state.placingAnnotationIconPageCoords = {
        ...action.payload.pageCoords,
        pageIndex: action.payload.pageIndex,
      };
    },
    startEditAnnotation: {
      reducer: (state, action) => {
        state.editingAnnotations[action.payload.annotationId] =
         state.annotations[action.payload.annotationId];
      },
      prepare: (annotationId) => addMetaLabel('start-edit-annotation', { annotationId })
    },
    cancelEditAnnotation: {
      reducer: (state, action) => {
        state.editingAnnotations[action.payload.annotationId] = null;
      },
      prepare: (annotationId) => addMetaLabel('cancel-edit-annotation', { annotationId })
    },
    updateAnnotationContent: {
      reducer: (state, action) => {
        state.editingAnnotations[action.payload.annotationId].comment = action.payload.content;
      },
      prepare: (annotationId, content) => addMetaLabel('edit-annotation-content-locally', { annotationId, content })
    },
    updateAnnotationRelevantDate: {
      reducer: (state, action) => {
        state.editingAnnotations[action.payload.annotationId].relevant_date =
         action.payload.relevantDate;
      },
      prepare: (relevantDate, annotationId) => addMetaLabel('', { annotationId, relevantDate })
    },
    updateNewAnnotationContent: {
      reducer: (state, action) => {
        state.placedButUnsavedAnnotation.comment = action.payload.content;
      },
      prepare: (content) => addMetaLabel('', { content })
    },
    updateNewAnnotationRelevantDate: {
      reducer: (state, action) => {
        state.placedButUnsavedAnnotation.relevant_date = action.payload.relevantDate;
      },
      prepare: (relevantDate) => addMetaLabel('', { relevantDate })
    }
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
      addMatcher((action) => action.type === setPageNumber.toString(), (state, action) => {
        // Reset the selected state on scroll or changing page
        state.selected = {};
      }).
      addMatcher((action) => action.type === loadDocuments.fulfilled.toString(), (state, action) => {
        // Map the Annotations to the comments array
        state.comments = action.payload.annotations;
      });
  }
});

// Export the Reducer actions
export const {
  openAnnotationDeleteModal,
  closeAnnotationDeleteModal,
  openAnnotationShareModal,
  closeAnnotationShareModal,
  selectComment,
  startPlacingAnnotation,
  stopPlacingAnnotation,
  onReceiveAnnotations,
  placeAnnotation,
  showPlaceAnnotationIcon,
  startEditAnnotation,
  cancelEditAnnotation,
  updateAnnotationContent,
  updateAnnotationRelevantDate,
  updateNewAnnotationContent,
  updateNewAnnotationRelevantDate,
  startEdit,
  updateComment,
  addComment,
  dropComment,
  cancelDrop,
  startMove
} = annotationLayerSlice.actions;

// Default export the reducer
export default annotationLayerSlice.reducer;
