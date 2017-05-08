import { expect } from 'chai';
import * as Constants from '../../../app/manageEstablishClaim/constants';
import manageEstablishClaimReducer, { getManageEstablishClaimInitialState } from
  '../../../app/manageEstablishClaim/reducers/index';

describe('manageEstablishClaimReducer', () => {
  let initialState;

  beforeEach(() => {
    initialState = getManageEstablishClaimInitialState();
  });

  context(Constants.CHANGE_EMPLOYEE_COUNT, () => {
    let state;

    beforeEach(() => {
      state = manageEstablishClaimReducer(initialState, {
        type: Constants.CHANGE_EMPLOYEE_COUNT,
        payload: { employeeCount: 7 }
      });
    });

    it('updates value', () => {
      expect(state.employeeCount).to.eq(7);
    });
  });

  context(Constants.CLEAR_ALERT, () => {
    let state;

    beforeEach(() => {
      initialState.alert = 'ALERT!';
      state = manageEstablishClaimReducer(initialState, { type: Constants.CLEAR_ALERT });
    });

    it('updates value', () => {
      expect(state.alert).to.eq(null);
    });
  });
});

