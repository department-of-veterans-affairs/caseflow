import { expect } from 'chai';
import documentsReducer from '../../../../app/reader/Documents/DocumentsReducer';
import * as Constants from '../../../../app/reader/Documents/actionTypes';

describe('Documents reducer', () => {
  const reduceActions = (actions, state) => actions.reduce(documentsReducer, documentsReducer(state, {}));

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
