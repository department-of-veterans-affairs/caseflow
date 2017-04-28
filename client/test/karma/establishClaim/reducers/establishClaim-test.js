import { expect } from 'chai';
import * as Constants from '../../../../app/establishClaim/constants';
import establishClaimReducer, { getEstablishClaimInitialState } from
  '../../../../app/establishClaim/reducers/index';

describe('establishClaimReducer', () => {
  let initialState;

  beforeEach(() => {
    initialState = getEstablishClaimInitialState();
  });

  context(Constants.TOGGLE_CANCEL_TASK_MODAL, () => {
    let state;

    beforeEach(() => {
      state = establishClaimReducer(initialState, {
        type: Constants.TOGGLE_CANCEL_TASK_MODAL
      });
    });

    it('toggles value', () => {
      expect(state.isShowingCancelModal).to.eq(true);
    });
  });

  context(Constants.REQUEST_CANCEL_FEEDBACK_FAILURE, () => {
    let state;

    beforeEach(() => {
      // Set state such that the modal is currently submitting
      initialState.isShowingCancelModal = true;
      initialState.isSubmittingCancelFeedback = true;
      initialState.isValidating = true;

      state = establishClaimReducer(initialState, {
        type: Constants.REQUEST_CANCEL_FEEDBACK_FAILURE
      });
    });

    it('resets all submit state on failure', () => {
      expect(state.isShowingCancelModal).to.eq(false);
      expect(state.isSubmittingCancelFeedback).to.eq(false);
      expect(state.isValidating).to.eq(false);
    });

  });
});

