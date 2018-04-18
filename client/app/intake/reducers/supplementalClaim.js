import { ACTIONS, REQUEST_STATE, FORM_TYPES } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import { getReceiptDateError } from '../util';

const updateFromServerIntake = (state, serverIntake) => {
  if (serverIntake.form_type !== FORM_TYPES.SUPPLEMENTAL_CLAIM.key) {
    return state;
  }

  return update(state, {
    isStarted: {
      $set: Boolean(serverIntake.id)
    },
    receiptDate: {
      $set: serverIntake.receipt_date && formatDateStr(serverIntake.receipt_date)
    },
    isReviewed: {
      $set: Boolean(serverIntake.receipt_date)
    },
    isComplete: {
      $set: Boolean(serverIntake.completed_at)
    }
  });
};

export const mapDataToInitialSupplementalClaim = (data = { serverIntake: {} }) => (
  updateFromServerIntake({
    receiptDate: null,
    receiptDateError: null,
    isStarted: false,
    isReviewed: false,
    isComplete: false,
    requestStatus: {
      submitReview: REQUEST_STATE.NOT_STARTED
    }
  }, data.serverIntake)
);

export const supplementalClaimReducer = (state = mapDataToInitialSupplementalClaim(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialSupplementalClaim();
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateFromServerIntake(state, action.payload.intake);
  default:
  }

  // The rest of the actions only should be processed if a SupplementalClaim intake is being processed
  if (!state.isStarted) {
    return state;
  }

  switch (action.type) {
  case ACTIONS.CANCEL_INTAKE_SUCCEED:
    return mapDataToInitialSupplementalClaim();
  case ACTIONS.SET_RECEIPT_DATE:
    return update(state, {
      receiptDate: {
        $set: action.payload.receiptDate
      }
    });
  case ACTIONS.SUBMIT_REVIEW_START:
    return update(state, {
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.SUBMIT_REVIEW_SUCCEED:
    return update(state, {
      receiptDateError: {
        $set: null
      },
      isReviewed: {
        $set: true
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    });
  case ACTIONS.SUBMIT_REVIEW_FAIL:
    return update(state, {
      receiptDateError: {
        $set: getReceiptDateError(action.payload.responseErrorCodes, state)
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.FAILED
        }
      }
    });
  default:
    return state;
  }
};
