import { expect } from 'chai';
import { readerReducer, initialState } from '../../../../app/reader/reducer';
import { setViewingDocumentsOrComments } from '../../../../app/reader/DocumentList/DocumentListActions';
import * as Constants from '../../../../app/reader/constants';

/* eslint-disable no-undefined */

describe('Reader reducer', () => {

  const reduceActions = (actions, state) => actions.reduce(readerReducer, readerReducer(state, {}));

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
            documents
          }
        },
        {
          type: Constants.SET_LOADED_APPEAL_ID,
          payload: {
            vacolsId
          }
        }
      ]);

      expect(state.documents[documents[0].id]).to.deep.equal(documents[0]);
      expect(state.loadedAppealId).to.deep.equal(vacolsId);
    });

    it('updates documents object when null is passed', () => {
      const documents = null;
      const state = reduceActions([
        {
          type: Constants.RECEIVE_DOCUMENTS,
          payload: {
            documents
          }
        },
        {
          type: Constants.SET_LOADED_APPEAL_ID,
          payload: { }
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
