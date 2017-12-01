/* eslint-disable max-lines */
import { expect } from 'chai';
import { reducer, initialState } from '../../../app/reader/reducer';
import { setViewingDocumentsOrComments } from '../../../app/reader/actions';
import * as Constants from '../../../app/reader/constants';

/* eslint-disable no-undefined */

describe('Reader reducer', () => {

  const reduceActions = (actions, state) => actions.reduce(reducer, reducer(state, {}));

  describe(Constants.SET_VIEWING_DOCUMENTS_OR_COMMENTS, () => {
    it('switching to Comments mode', () => {
      const state = {
        ...initialState,
        documents: {
          0: {
            id: 0,
            listComments: false
          },
          1: {
            id: 1,
            listComments: true
          }
        }
      };

      const nextState = reduceActions([
        setViewingDocumentsOrComments(Constants.DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS)
      ], state);

      expect(nextState).to.deep.equal({
        ...initialState,
        documents: {
          0: {
            id: 0,
            listComments: true
          },
          1: {
            id: 1,
            listComments: true
          }
        },
        viewingDocumentsOrComments: Constants.DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS
      });
    });

    it('switching to Documents mode', () => {
      const state = {
        ...initialState,
        documents: {
          0: {
            id: 0,
            listComments: false
          },
          1: {
            id: 1,
            listComments: true
          }
        }
      };

      const nextState = reduceActions([
        setViewingDocumentsOrComments(Constants.DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS)
      ], state);

      expect(nextState).to.deep.equal({
        ...initialState,
        documents: {
          0: {
            id: 0,
            listComments: false
          },
          1: {
            id: 1,
            listComments: false
          }
        }
      });
    });
  });

  describe(Constants.RECEIVE_DOCUMENTS, () => {
    it('updates documents object when received', () => {
      const date = new Date();
      const documents = [{
        id: 0,
        tags: [],
        receivedAt: date,
        received_at: date,
        listComments: false
      }];
      const vacolsId = 1;
      const state = reduceActions([
        {
          type: Constants.RECEIVE_DOCUMENTS,
          payload: {
            documents,
            vacolsId
          }
        }
      ]);

      expect(state.documents[documents[0].id]).to.deep.equal(documents[0]);
      expect(state.loadedAppealId).to.deep.equal(vacolsId);
      expect(state.assignments).to.deep.equal([]);
    });

    it('updates that assignment is viewed when documents are received', () => {
      const vacolsId = 1;
      const date = new Date();
      const assignments = [{
        viewed: false,
        vacols_id: vacolsId
      }];
      const documents = [{
        id: 0,
        tags: [],
        receivedAt: date,
        received_at: date,
        listComments: false
      }];
      const state = reduceActions([
        {
          type: Constants.RECEIVE_ASSIGNMENTS,
          payload: {
            assignments
          }
        },
        {
          type: Constants.RECEIVE_DOCUMENTS,
          payload: {
            documents,
            vacolsId
          }
        }
      ]);

      expect(state.assignments[0].viewed).to.deep.equal(true);
    });

    it('updates documents object when null is passed', () => {
      const documents = null;
      const state = reduceActions([
        {
          type: Constants.RECEIVE_DOCUMENTS,
          payload: {
            documents
          }
        }
      ]);

      expect(state.documents).to.deep.equal({});
      expect(state.loadedAppealId).to.equal(undefined);
    });
  });

  describe(Constants.REQUEST_INITIAL_DATA_FAILURE, () => {
    const state = reduceActions([{
      type: Constants.REQUEST_INITIAL_DATA_FAILURE,
      payload: {
        value: true
      }
    }]);

    expect(state.initialDataLoadingFail).to.equal(true);
  });

  describe(Constants.REQUEST_INITIAL_CASE_FAILURE, () => {
    const state = reduceActions([{
      type: Constants.REQUEST_INITIAL_CASE_FAILURE,
      payload: {
        value: true
      }
    }]);

    expect(state.initialCaseLoadingFail).to.equal(true);
  });

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

    it('shows an error message when creating the annotation fails', () => {
      const { state, annotation } = getContext();

      expect(state.ui.pdfSidebar.showErrorMessage.annotation).to.equal(true);
      expect(state.ui.placedButUnsavedAnnotation).to.deep.equal(annotation);
    });

    it('hides the error message when a second request is started', () => {
      const { state } = getContext();

      const nextState = reduceActions([
        {
          type: Constants.REQUEST_CREATE_ANNOTATION,
          payload: {
            annotation: {
              comment: 'a second annotation',
              id: 'some-other-guid'
            }
          }
        }
      ], state);

      expect(nextState.ui.pdfSidebar.showErrorMessage.annotation).to.equal(false);
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

      expect(stateAfterDeleteRequest.ui.pdfSidebar.showErrorMessage.annotation).to.equal(false);
      expect(stateAfterDeleteRequest.annotations[annotationId].pendingDeletion).to.equal(true);
    });

    it('shows an error message when the request fails', () => {
      const { stateAfterDeleteFailure, annotationId } = getContext();

      expect(stateAfterDeleteFailure.ui.pdfSidebar.showErrorMessage.annotation).to.equal(true);
      expect(stateAfterDeleteFailure.annotations[annotationId].pendingDeletion).to.equal(undefined);
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

      expect(stateAfterEditRequest.ui.pdfSidebar.showErrorMessage.annotation).to.equal(false);
      expect(stateAfterEditRequest.ui.pendingEditingAnnotations[annotationId]).to.deep.equal({
        id: annotationId,
        uuid: annotationId,
        comment: newContent,
        documentId
      });
    });

    it('shows an error message when the request fails', () => {
      const { stateAfterEditFailure, annotationId, newContent, documentId } = getContext();

      expect(stateAfterEditFailure.ui.pdfSidebar.showErrorMessage.annotation).to.equal(true);
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

      expect(stateAfterMoveRequest.ui.pdfSidebar.showErrorMessage.annotation).to.equal(false);
      expect(stateAfterMoveRequest.ui.pendingEditingAnnotations[annotation.id]).to.deep.equal(movedAnnotation);
    });

    it('shows an error message when the request fails', () => {
      const { stateAfterMoveFailure, annotation } = getContext();

      expect(stateAfterMoveFailure.ui.pdfSidebar.showErrorMessage.annotation).to.equal(true);
      expect(stateAfterMoveFailure.ui.pendingEditingAnnotations[annotation.id]).to.equal(undefined);
    });

    it('updates the annotation when the request succeeds', () => {
      const { stateAfterMoveSuccess, annotation, movedAnnotation } = getContext();

      expect(stateAfterMoveSuccess.ui.pdfSidebar.showErrorMessage.annotation).to.equal(false);
      expect(stateAfterMoveSuccess.ui.pendingEditingAnnotations[annotation.id]).to.equal(undefined);
      expect(stateAfterMoveSuccess.annotations[annotation.id]).to.deep.equal(movedAnnotation);
    });
  });

  describe(Constants.REQUEST_CREATE_ANNOTATION_SUCCESS, () => {
    it('updates annotations when the server save is successful', () => {
      const docId = 3;
      const annotationId = 100;
      const state = reduceActions([
        {
          type: Constants.RECEIVE_DOCUMENTS,
          payload: {
            documents: [{
              id: docId,
              tags: []
            }],
            vacolsId: 1
          }
        },
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

      expect(state.ui.pendingAnnotations).to.deep.equal({});
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

  describe(Constants.REQUEST_NEW_TAG_CREATION_SUCCESS, () => {
    it('successfully merges tags', () => {
      const state = reduceActions([
        {
          type: Constants.RECEIVE_DOCUMENTS,
          payload: {
            documents: [{
              id: 0,
              tags: []
            }],
            vacolsId: 1
          }
        },
        {
          type: Constants.REQUEST_NEW_TAG_CREATION,
          payload: {
            newTags: [{ text: 'first tag' }],
            docId: 0
          }
        },
        {
          type: Constants.REQUEST_NEW_TAG_CREATION,
          payload: {
            newTags: [{ text: 'second tag' }],
            docId: 0
          }
        },
        {
          type: Constants.REQUEST_NEW_TAG_CREATION_SUCCESS,
          payload: {
            createdTags: [{
              text: 'first tag',
              id: 100
            }],
            docId: 0
          }
        }
      ]);

      expect(state.documents[0].tags).to.deep.equal([
        {
          text: 'first tag',
          id: 100
        },
        {
          text: 'second tag'
        }
      ]);
    });
  });

  describe(Constants.RECEIVE_APPEAL_DETAILS_FAILURE, () => {
    const getContext = () => {
      const stateAfterFetchFailure = {
        didLoadAppealFail: false
      };

      return {
        stateAfterFetchFailure: reduceActions([
          {
            type: Constants.RECEIVE_APPEAL_DETAILS_FAILURE,
            payload: {
              failedToLoad: true
            }
          },
          stateAfterFetchFailure])
      };
    };

    it('shows an error message when the request fails', () => {
      const { stateAfterFetchFailure } = getContext();

      expect(stateAfterFetchFailure.didLoadAppealFail).to.equal(true);
    });
  });
});
