import { expect } from 'chai';
import { annotationLayerReducer } from '../../../../app/reader/AnnotationLayer/AnnotationLayerReducer';
import * as Constants from '../../../../app/reader/AnnotationLayer/actionTypes';

describe('AnnotationLayerReducer reducer', () => {

  const reduceActions = (actions, state) => actions.reduce(annotationLayerReducer, annotationLayerReducer(state, {}));

  describe(Constants.REQUEST_CREATE_ANNOTATION_FAILURE, () => {
    const getContext = () => {
      const annotationTemporaryId = 'some-guid';
      const annotation = {
        comment: 'text',
        id: annotationTemporaryId
      };

      return {
        state: reduceActions([
          {
            type: Constants.REQUEST_CREATE_ANNOTATION,
            payload: {
              annotation
            }
          },
          {
            type: Constants.REQUEST_CREATE_ANNOTATION_FAILURE,
            payload: {
              annotationTemporaryId
            }
          }
        ]),
        annotation
      };
    };

    it('annotation stay pending when the annotation creation fails', () => {
      const { state, annotation } = getContext();

      expect(state.placedButUnsavedAnnotation).to.deep.equal(annotation);
    });

    it('annotation becomes pending when annotation creation requested', () => {
      const { state } = getContext();
      const annotationId = 'some-other-guid';
      const annotation = {
        comment: 'a second annotation',
        id: annotationId
      };

      const nextState = reduceActions([
        {
          type: Constants.REQUEST_CREATE_ANNOTATION,
          payload: {
            annotation
          }
        }
      ], state);

      expect(nextState.placedButUnsavedAnnotation).to.deep.equal(null);
      expect(nextState.pendingAnnotations[annotationId]).to.deep.equal(annotation);
    });
  });

  describe(Constants.REQUEST_DELETE_ANNOTATION_FAILURE, () => {
    const getContext = () => {
      const annotationActualId = 800;
      const annotationTemporaryId = 'some-guid';
      const annotation = {
        comment: 'text',
        id: annotationTemporaryId
      };
      const stateAfterDeleteRequest = reduceActions([
        {
          type: Constants.REQUEST_CREATE_ANNOTATION,
          payload: {
            annotation
          }
        },
        {
          type: Constants.REQUEST_CREATE_ANNOTATION_SUCCESS,
          payload: {
            annotation: {
              id: annotationActualId
            },
            annotationTemporaryId
          }
        },
        {
          type: Constants.REQUEST_DELETE_ANNOTATION,
          payload: {
            annotationId: annotationActualId
          }
        }]);

      return {
        stateAfterDeleteRequest,
        stateAfterDeleteFailure: reduceActions([
          {
            type: Constants.REQUEST_DELETE_ANNOTATION_FAILURE,
            payload: {
              annotationId: annotationActualId
            }
          }
        ], stateAfterDeleteRequest),
        annotationId: annotationActualId
      };
    };

    it('marks an annotation as pending deletion', () => {
      const { stateAfterDeleteRequest, annotationId } = getContext();

      expect(stateAfterDeleteRequest.annotations[annotationId].pendingDeletion).to.equal(true);
    });
  });

  describe(Constants.REQUEST_EDIT_ANNOTATION_FAILURE, () => {
    const getContext = () => {
      const annotationId = 886;
      const newContent = 'new content';
      const documentId = 14;
      const stateAfterEditRequest = reduceActions([
        {
          type: Constants.RECEIVE_ANNOTATIONS,
          payload: {
            annotations: [{
              id: annotationId,
              comment: 'original content',
              documentId
            }]
          }
        },
        {
          type: Constants.START_EDIT_ANNOTATION,
          payload: {
            annotationId
          }
        },
        {
          type: Constants.UPDATE_ANNOTATION_CONTENT,
          payload: {
            annotationId,
            content: newContent
          }
        },
        {
          type: Constants.REQUEST_EDIT_ANNOTATION,
          payload: {
            annotationId
          }
        }]);

      return {
        stateAfterEditRequest,
        stateAfterEditFailure: reduceActions([
          {
            type: Constants.REQUEST_EDIT_ANNOTATION_FAILURE,
            payload: {
              annotationId
            }
          }
        ], stateAfterEditRequest),
        annotationId,
        newContent,
        documentId
      };
    };

    it('handles editing an annotation', () => {
      const { stateAfterEditRequest, annotationId, newContent, documentId } = getContext();

      expect(stateAfterEditRequest.pendingEditingAnnotations[annotationId]).to.deep.equal({
        id: annotationId,
        uuid: annotationId,
        comment: newContent,
        documentId
      });
    });

    it('pending edit stays when the request fails', () => {
      const { stateAfterEditFailure, annotationId, newContent, documentId } = getContext();

      expect(stateAfterEditFailure.editingAnnotations[annotationId]).to.deep.equal({
        id: annotationId,
        uuid: annotationId,
        comment: newContent,
        documentId
      });
    });
  });

  describe(Constants.REQUEST_MOVE_ANNOTATION_FAILURE, () => {
    const getContext = () => {
      const annotationId = 8236;
      const annotation = {
        id: annotationId,
        x: 34,
        y: 67,
        documentId: 5
      };
      const movedAnnotation = {
        ...annotation,
        x: 500,
        y: 600
      };
      const stateAfterMoveRequest = reduceActions([
        {
          type: Constants.RECEIVE_ANNOTATIONS,
          payload: {
            annotations: [annotation]
          }
        },
        {
          type: Constants.REQUEST_MOVE_ANNOTATION,
          payload: {
            annotation: movedAnnotation
          }
        }]);

      return {
        stateAfterMoveRequest,
        stateAfterMoveFailure: reduceActions([
          {
            type: Constants.REQUEST_MOVE_ANNOTATION_FAILURE,
            payload: {
              annotationId
            }
          }
        ], stateAfterMoveRequest),
        stateAfterMoveSuccess: reduceActions([
          {
            type: Constants.REQUEST_MOVE_ANNOTATION_SUCCESS,
            payload: {
              annotationId
            }
          }
        ], stateAfterMoveRequest),
        annotation,
        movedAnnotation
      };
    };

    it('handles moving an annotation', () => {
      const { stateAfterMoveRequest, annotation, movedAnnotation } = getContext();

      expect(stateAfterMoveRequest.pendingEditingAnnotations[annotation.id]).to.deep.equal(movedAnnotation);
    });

    it('no edits pending with the request fails', () => {
      const { stateAfterMoveFailure, annotation } = getContext();

      expect(stateAfterMoveFailure.pendingEditingAnnotations[annotation.id]).to.equal(undefined);
    });

    it('updates the annotation when the request succeeds', () => {
      const { stateAfterMoveSuccess, annotation, movedAnnotation } = getContext();

      expect(stateAfterMoveSuccess.pendingEditingAnnotations[annotation.id]).to.equal(undefined);
      expect(stateAfterMoveSuccess.annotations[annotation.id]).to.deep.equal(movedAnnotation);
    });
  });

  describe(Constants.REQUEST_CREATE_ANNOTATION_SUCCESS, () => {
    it('updates annotations when the server save is successful', () => {
      const docId = 3;
      const annotationId = 100;
      const state = reduceActions([
        {
          type: Constants.REQUEST_CREATE_ANNOTATION,
          payload: {
            annotation: {
              documentId: docId,
              comment: 'annotation text'
            }
          }
        },
        {
          type: Constants.REQUEST_CREATE_ANNOTATION_SUCCESS,
          payload: {
            annotation: {
              id: annotationId,
              documentId: docId,
              comment: 'annotation text'
            }
          }
        }
      ]);

      expect(state.pendingAnnotations).to.deep.equal({});
      expect(state.annotations).to.deep.equal({
        [annotationId]: {
          id: annotationId,
          uuid: annotationId,
          documentId: docId,
          document_id: docId,
          comment: 'annotation text'
        }
      });

      const nextAnnotationId = 200;
      const stateWithNextAnnotation = reduceActions([
        {
          type: Constants.REQUEST_CREATE_ANNOTATION,
          payload: {
            annotation: {
              documentId: docId,
              comment: 'next annotation text'
            }
          }
        },
        {
          type: Constants.REQUEST_CREATE_ANNOTATION_SUCCESS,
          payload: {
            annotation: {
              id: nextAnnotationId,
              documentId: docId,
              comment: 'next annotation text'
            }
          }
        }
      ], state);

      expect(stateWithNextAnnotation.annotations).to.deep.equal({
        [annotationId]: {
          id: annotationId,
          uuid: annotationId,
          documentId: docId,
          document_id: docId,
          comment: 'annotation text'
        },
        [nextAnnotationId]: {
          id: nextAnnotationId,
          uuid: nextAnnotationId,
          documentId: docId,
          document_id: docId,
          comment: 'next annotation text'
        }
      });
    });
  });
});
