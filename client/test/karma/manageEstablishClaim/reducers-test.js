import { expect } from 'chai';
import * as Constants from '../../../app/manageEstablishClaim/constants';
import manageEstablishClaimReducer, { getManageEstablishClaimInitialState } from
  '../../../app/manageEstablishClaim/reducers/index';

/* eslint-disable no-unused-expressions */
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
    expect(state.userQuotas[0].userName).to.equal('Not logged in');
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
    initialState = getManageEstablishClaimInitialState({
      userQuotas: [
        {
          user_name: 'Steph Curry',
          task_count: 5,
          tasks_completed_count: 0,
          tasks_left_count: 5
        },
        {
          user_name: 'Klay Thompson',
          task_count: 7,
          tasks_completed_count: 3,
          tasks_left_count: 4
        },
        {
          user_name: 'Draymond Green',
          task_count: 7,
          tasks_completed_count: 3,
          tasks_left_count: 4
        }
      ]
    });
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
            id: 'DRAY',
            user_name: 'Draymond Green',
            task_count: 7,
            tasks_completed_count: 3,
            tasks_completed_count_by_decision_type: {
              full_grant: 1,
              partial_grant: 2,
              remand_grant: 3
            },
            tasks_left_count: 4,
            'locked?': true
          },
          {
            id: null,
            user_name: null,
            task_count: 7,
            tasks_completed_count: 0,
            tasks_completed_count_by_decision_type: {},
            tasks_left_count: 7
          }
        ] }
      });
    });

    it('updates quotas and employeeCount', () => {
      expect(state.userQuotas[0]).to.deep.equal({
        id: 'DRAY',
        index: 0,
        userName: 'Draymond Green',
        taskCount: 7,
        tasksCompletedCount: 3,
        tasksCompletedCountByDecisionType: {
          full_grant: 1,
          partial_grant: 2,
          remand_grant: 3
        },
        isEditingTaskCount: false,
        tasksLeftCount: 4,
        isAssigned: true,
        isLocked: true
      });

      expect(state.userQuotas[1]).to.deep.equal({
        id: null,
        index: 1,
        userName: 'Not logged in',
        taskCount: 7,
        isEditingTaskCount: false,
        tasksCompletedCount: 0,
        tasksCompletedCountByDecisionType: {},
        tasksLeftCount: 7,
        isAssigned: false,
        isLocked: false
      });

      expect(state.employeeCount).to.equal(2);
    });
  });

  context(Constants.BEGIN_EDIT_TASK_COUNT, () => {
    let state;

    beforeEach(() => {
      state = manageEstablishClaimReducer(initialState, {
        type: Constants.BEGIN_EDIT_TASK_COUNT,
        payload: { userQuotaIndex: 2 }
      });
    });

    it('sets taskCountEdit on userQuota', () => {
      expect(state.userQuotas[0].isEditingTaskCount).to.equal(false);
      expect(state.userQuotas[0].newTaskCount).to.not.exist;
      expect(state.userQuotas[1].isEditingTaskCount).to.equal(false);
      expect(state.userQuotas[1].newTaskCount).to.not.exist;
      expect(state.userQuotas[2].isEditingTaskCount).to.equal(true);
      expect(state.userQuotas[2].newTaskCount).to.equal(7);
    });
  });

  context(Constants.CHANGE_NEW_TASK_COUNT, () => {
    let state;

    beforeEach(() => {
      state = manageEstablishClaimReducer(initialState, {
        type: Constants.CHANGE_NEW_TASK_COUNT,
        payload: { userQuotaIndex: 1,
          taskCount: 40 }
      });
    });

    it('sets taskCountEdit on userQuota', () => {
      expect(state.userQuotas[0].newTaskCount).to.not.exist;
      expect(state.userQuotas[1].newTaskCount).to.equal(40);
      expect(state.userQuotas[2].newTaskCount).to.not.exist;
    });

  });
});
/* eslint-enable no-unused-expressions */
