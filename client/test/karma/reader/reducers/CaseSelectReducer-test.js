import { expect } from 'chai';
import {
  caseSelectReducer, initialState as caseSelectInitialState
} from '../../../../app/reader/CaseSelect/CaseSelectReducer';
import * as CaseSelectConstants from '../../../../app/reader/CaseSelect/actionTypes';

describe('CaseSelect reducer', () => {
  const reduceActions = (actions, state) => actions.reduce(caseSelectReducer, caseSelectReducer(state, {}));

  it('updates assignment as viewed', () => {
    const vacolsId = 1;
    const assignments = [{
      viewed: false,
      vacols_id: vacolsId
    }];

    const state = reduceActions([
      {
        type: CaseSelectConstants.RECEIVE_ASSIGNMENTS,
        payload: {
          assignments
        }
      },
      {
        type: CaseSelectConstants.SET_VIEWED_ASSIGNMENT,
        payload: {
          vacolsId
        }
      }
    ], caseSelectInitialState);

    expect(state.assignments[0].viewed).to.deep.equal(true);
  });
});
