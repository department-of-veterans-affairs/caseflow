import { expect } from 'chai';
import documentsReducer from '../../../../app/reader/Documents/DocumentsReducer';
import { setViewingDocumentsOrComments } from '../../../../app/reader/DocumentList/DocumentListActions';
import * as Constants from '../../../../app/reader/Documents/actionTypes';

describe('CaseSelect reducer', () => {
  const reduceActions = (actions, state) => actions.reduce(documentsReducer, documentsReducer(state, {}));

  describe(Constants.SET_VIEWING_DOCUMENTS_OR_COMMENTS, () => {
    it('switching to Comments mode', () => {
      const state = {
        0: {
          id: 0,
          listComments: false
        },
        1: {
          id: 1,
          listComments: true
        }
      };

      const nextState = reduceActions([
        setViewingDocumentsOrComments(Constants.DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS)
      ], state);

      expect(nextState).to.deep.equal({
        0: {
          id: 0,
          listComments: true
        },
        1: {
          id: 1,
          listComments: true
        }
      });
    });

    it('switching to Documents mode', () => {
      const state = {
        0: {
          id: 0,
          listComments: false
        },
        1: {
          id: 1,
          listComments: true
        }
      };

      const nextState = reduceActions([
        setViewingDocumentsOrComments(Constants.DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS)
      ], state);

      expect(nextState).to.deep.equal({
        0: {
          id: 0,
          listComments: false
        },
        1: {
          id: 1,
          listComments: false
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
      const state = reduceActions([
        {
          type: Constants.RECEIVE_DOCUMENTS,
          payload: {
            documents
          }
        }
      ]);

      expect(state[documents[0].id]).to.deep.equal(documents[0]);
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

      expect(state).to.deep.equal({});
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

      expect(state[0].tags).to.deep.equal([
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
});
