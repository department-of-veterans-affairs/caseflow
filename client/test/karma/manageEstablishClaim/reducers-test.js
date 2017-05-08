import { expect } from 'chai';
import * as Constants from '../../../app/manageEstablishClaim/constants';
import manageEstablishClaimReducer, { getManageEstablishClaimInitialState } from
  '../../../app/manageEstablishClaim/reducers/index';

describe('getManageEstablishClaimInitialState', () => {
  let state;

  beforeEach(() => {
    state = getManageEstablishClaimInitialState({
      userQuotas: [
        {
          user_name: null,
          task_count: 5,
          tasks_completed_count: 0,
          tasks_left_count: 5
        }
      ]
    });
  });

  it('updates quotas and employeeCount', () => {
    expect(state.userQuotas[0].userName).to.equal('1. Not logged in');
    expect(state.userQuotas[0].taskCount).to.equal(5);
    expect(state.userQuotas[0].tasksCompletedCount).to.equal(0);
    expect(state.userQuotas[0].tasksLeftCount).to.equal(5);
    expect(state.userQuotas[0].isAssigned).to.equal(false);

    expect(state.employeeCount).to.eql(1);
  });
});

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

  context(Constants.REQUEST_USER_QUOTAS_SUCCESS, () => {
    let state;

    beforeEach(() => {
      state = manageEstablishClaimReducer(initialState, {
        type: Constants.REQUEST_USER_QUOTAS_SUCCESS,
        payload: { userQuotas: [
          {
            user_name: 'Draymond Green',
            task_count: 7,
            tasks_completed_count: 3,
            tasks_left_count: 4
          },
          {
            user_name: null,
            task_count: 7,
            tasks_completed_count: 0,
            tasks_left_count: 7
          }
        ] }
      });
    });

    it('updates quotas and employeeCount', () => {
      expect(state.userQuotas[0]).to.eql({
        userName: '1. Draymond Green',
        taskCount: 7,
        tasksCompletedCount: 3,
        tasksLeftCount: 4,
        isAssigned: true
      });

      expect(state.userQuotas[1]).to.eql({
        userName: '2. Not logged in',
        taskCount: 7,
        tasksCompletedCount: 0,
        tasksLeftCount: 7,
        isAssigned: false
      });

      expect(state.employeeCount).to.eql(2);
    });
  });
});

