import { ACTIONS, REQUEST_STATE, FORM_TYPES } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import { getReceiptDateError } from '../util';
import _ from 'lodash';

const formatRatings = (ratings) => {
  return _.keyBy(_.map(ratings, (rating) => {
    return _.assign(rating,
      { issues: _.keyBy(rating.issues, 'rba_issue_id') }
    );
  }), 'profile_date');
};

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
    ratings: {
      $set: state.ratings || formatRatings(serverIntake.ratings)
    },
    isComplete: {
      $set: Boolean(serverIntake.completed_at)
    },
    endProductDescription: {
      $set: serverIntake.end_product_description
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
    endProductDescription: null,
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
  case ACTIONS.COMPLETE_INTAKE_START:
    return update(state, {
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.COMPLETE_INTAKE_SUCCEED:
    return updateFromServerIntake(update(state, {
      isComplete: {
        $set: true
      },
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    }), action.payload.intake);
  case ACTIONS.COMPLETE_INTAKE_FAIL:
    return update(state, {
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.FAILED
        },
        completeIntakeErrorCode: {
          $set: action.payload.responseErrorCode
        },
        completeIntakeErrorData: {
          $set: action.payload.responseErrorData
        }
      }
    });
  case ACTIONS.SET_ISSUE_SELECTED:
    return update(state, {
      ratings: {
        [action.payload.profileDate]: {
          issues: {
            [action.payload.issueId]: {
              isSelected: {
                $set: action.payload.isSelected
              }
            }
          }
        }
      }
    });
  default:
    return state;
  }
};
