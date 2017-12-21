import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';
import _ from 'lodash';
import { moveModel } from '../utils';

const toggleAnnotationDeleteModalFor = (state, annotationId) =>
  update(state, {
    deleteAnnotationModalIsOpenFor: {
      $set: annotationId
    }
  });

const initialState = {
  annotations: {},
  placingAnnotationIconPageCoords: null,
  pendingAnnotations: {},
  pendingEditingAnnotations: {},
  selectedAnnotationId: null,
  deleteAnnotationModalIsOpenFor: null,
  placedButUnsavedAnnotation: null,
  isPlacingAnnotation: false,

  /**
   * `editingAnnotations` is an object of annotations that are currently being edited.
   * When a user starts editing an annotation, we copy it from `annotations` to `editingAnnotations`.
   * To commit the edits, we copy from `editingAnnotations` back into `annotations`.
   * To discard the edits, we delete from `editingAnnotations`.
   */
  editingAnnotations: {}
};

export const annotationLayerReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.OPEN_ANNOTATION_DELETE_MODAL:
    return toggleAnnotationDeleteModalFor(state, action.payload.annotationId);
  case Constants.CLOSE_ANNOTATION_DELETE_MODAL:
    return toggleAnnotationDeleteModalFor(state, null);
  case Constants.SHOW_PLACE_ANNOTATION_ICON:
    return update(state, {
      placingAnnotationIconPageCoords: {
        $set: {
          pageIndex: action.payload.pageIndex,
          ...action.payload.pageCoords
        }
      }
    });
  case Constants.STOP_PLACING_ANNOTATION:
    return update(state, {
      placingAnnotationIconPageCoords: {
        $set: null
      },
      placedButUnsavedAnnotation: { $set: null },
      isPlacingAnnotation: { $set: false }
    });
  case Constants.RECEIVE_ANNOTATIONS:
    return update(
      state,
      {
        annotations: {
          $set: _(action.payload.annotations).
            map((annotation) => ({
              documentId: annotation.document_id,
              uuid: annotation.id,
              ...annotation
            })).
            keyBy('id').
            value()
        }
      }
    );
  case Constants.REQUEST_DELETE_ANNOTATION:
    return update(state, {
      editingAnnotations: {
        [action.payload.annotationId]: {
          $apply: (annotation) => annotation && {
            ...annotation,
            pendingDeletion: true
          }
        }
      },
      annotations: {
        [action.payload.annotationId]: {
          $merge: {
            pendingDeletion: true
          }
        }
      }
    });
  case Constants.REQUEST_DELETE_ANNOTATION_FAILURE:
    return update(state, {
      editingAnnotations: {
        [action.payload.annotationId]: {
          $unset: 'pendingDeletion'
        }
      },
      annotations: {
        [action.payload.annotationId]: {
          $unset: 'pendingDeletion'
        }
      }
    });
  case Constants.REQUEST_DELETE_ANNOTATION_SUCCESS:
    return update(state, {
      editingAnnotations: {
        $unset: action.payload.annotationId
      },
      annotations: {
        $unset: action.payload.annotationId
      }
    });
  case Constants.REQUEST_CREATE_ANNOTATION:
    return update(state, {
      placedButUnsavedAnnotation: { $set: null },
      pendingAnnotations: {
        [action.payload.annotation.id]: {
          $set: action.payload.annotation
        }
      }
    });
  case Constants.REQUEST_CREATE_ANNOTATION_SUCCESS:
    return update(state, {
      pendingAnnotations: {
        $unset: action.payload.annotationTemporaryId
      },
      annotations: {
        [action.payload.annotation.id]: {
          $set: {
            // These two duplicate fields exist on annotations throughout the app.
            // I am not sure why this is, but we'll patch it here to make everything work.
            document_id: action.payload.annotation.documentId,
            uuid: action.payload.annotation.id,

            ...action.payload.annotation
          }
        }
      }
    });
  case Constants.REQUEST_CREATE_ANNOTATION_FAILURE:
    return update(state, {
      // This will cause a race condition if the user has created multiple annotations.
      // Whichever annotation failed most recently is the one that'll be in the
      // "new annotation" text box. For now, I think that's ok.
      placedButUnsavedAnnotation: {
        $set: state.pendingAnnotations[action.payload.annotationTemporaryId]
      },
      pendingAnnotations: {
        $unset: action.payload.annotationTemporaryId
      }
    });
  case Constants.START_EDIT_ANNOTATION:
    return update(state, {
      editingAnnotations: {
        [action.payload.annotationId]: {
          $set: state.annotations[action.payload.annotationId]
        }
      }
    });
  case Constants.CANCEL_EDIT_ANNOTATION:
    return update(state, {
      editingAnnotations: {
        $unset: action.payload.annotationId
      }
    });
  case Constants.UPDATE_ANNOTATION_CONTENT:
    return update(state, {
      editingAnnotations: {
        [action.payload.annotationId]: {
          comment: {
            $set: action.payload.content
          }
        }
      }
    });
  case Constants.REQUEST_EDIT_ANNOTATION:
    return moveModel(state,
      ['editingAnnotations'],
      ['pendingEditingAnnotations'],
      action.payload.annotationId
    );
  case Constants.REQUEST_EDIT_ANNOTATION_SUCCESS:
    return moveModel(state,
      ['pendingEditingAnnotations'],
      ['annotations'],
      action.payload.annotationId
    );
  case Constants.REQUEST_EDIT_ANNOTATION_FAILURE:
    return moveModel(state,
      ['pendingEditingAnnotations'],
      ['editingAnnotations'],
      action.payload.annotationId
    );
  case Constants.SELECT_ANNOTATION:
    return update(state, {
      selectedAnnotationId: {
        $set: action.payload.annotationId
      }
    });
  case Constants.REQUEST_MOVE_ANNOTATION:
    return update(state, {
      pendingEditingAnnotations: {
        [action.payload.annotation.id]: {
          $set: action.payload.annotation
        }
      }
    });
  case Constants.REQUEST_MOVE_ANNOTATION_SUCCESS:
    return moveModel(
      state,
      ['pendingEditingAnnotations'],
      ['annotations'],
      action.payload.annotationId
    );
  case Constants.REQUEST_MOVE_ANNOTATION_FAILURE:
    return update(state, {
      pendingEditingAnnotations: {
        $unset: action.payload.annotationId
      }
    });
  case Constants.PLACE_ANNOTATION:
    return update(state, {
      placedButUnsavedAnnotation: {
        $set: {
          ...action.payload,
          class: 'Annotation',
          type: 'point'
        }
      },
      isPlacingAnnotation: { $set: false }
    });
  case Constants.START_PLACING_ANNOTATION:
    return update(state, {
      isPlacingAnnotation: { $set: true }
    });
  case Constants.UPDATE_NEW_ANNOTATION_CONTENT:
    return update(state, {
      placedButUnsavedAnnotation: {
        comment: {
          $set: action.payload.content
        }
      }
    });
  default:
    return state;
  }
};

export default annotationLayerReducer;
