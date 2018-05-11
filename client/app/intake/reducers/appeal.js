import { ACTIONS, REQUEST_STATE, FORM_TYPES } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import { getReceiptDateError } from '../util';
import _ from 'lodash';

const getDocketTypeError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.docket_type, 0) === 'blank') && 'Please select an option.'
);

const updateFromServerIntake = (state, serverIntake) => {
  if (serverIntake.form_type !== FORM_TYPES.APPEAL.key) {
    return state;
  }

  return update(state, {
    isStarted: {
      $set: Boolean(serverIntake.id)
    },
    docketType: {
      $set: serverIntake.docket_type
    },
    receiptDate: {
      $set: serverIntake.receipt_date && formatDateStr(serverIntake.receipt_date)
    },
    isReviewed: {
      $set: Boolean(serverIntake.receipt_date)
    }
  });
};

export const mapDataToInitialAppeal = (data = { serverIntake: {} }) => (
  updateFromServerIntake({
    receiptDate: null,
    receiptDateError: null,
    docketType: null,
    docketTypeError: null,
    isStarted: false,
    isReviewed: false,
    endProductDescription: null,
    requestStatus: {
      submitReview: REQUEST_STATE.NOT_STARTED
    }
  }, data.serverIntake)
);

export const appealReducer = (state = mapDataToInitialAppeal(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialAppeal();
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateFromServerIntake(state, action.payload.intake);
  default:
  }

  // The rest of the actions only should be processed if a HigherLevelReview intake is being processed
  if (!state.isStarted) {
    return state;
  }

  switch (action.type) {
  case ACTIONS.CANCEL_INTAKE_SUCCEED:
    return mapDataToInitialAppeal();
  case ACTIONS.SET_DOCKET_TYPE:
    return update(state, {
      docketType: {
        $set: action.payload.docketType
      }
    });
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
      docketTypeError: {
        $set: null
      },
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
      docketTypeError: {
        $set: getDocketTypeError(action.payload.responseErrorCodes)
      },
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
