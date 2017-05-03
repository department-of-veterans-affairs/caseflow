import { expect } from 'chai';
import reducer from '../../../app/reader/reducer';
import * as Constants from '../../../app/reader/constants';

describe('Reader reducer', () => {
  describe(Constants.REQUEST_NEW_TAG_CREATION_SUCCESS, () => {
    it('successfully merges tags', () => {
      const reduceActions = (actions) => actions.reduce((action, state) => reducer(state, action));

      const state = reduceActions([
        {},
        {
          type: Constants.RECEIVE_DOCUMENTS,
          payload: [{
            id: 0
          }]
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
});
