import { ACTIONS, REQUEST_STATE, FORM_TYPES } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import { getReceiptDateError, formatRatings } from '../util';
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
    },
    ratings: {
      $set: state.ratings || formatRatings(serverIntake.ratings)
    },
    isComplete: {
      $set: Boolean(serverIntake.completed_at)
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
    isComplete: false,
    selectedRatingCount: 0,
    nonRatedIssues: { },
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

  // The rest of the actions only should be processed if a Appeal intake is being processed
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
      },
      selectedRatingCount: {
        $set: action.payload.isSelected ? state.selectedRatingCount + 1 : state.selectedRatingCount - 1
      }
    });
  case ACTIONS.ADD_NON_RATED_ISSUE:
    return update(state, {
      nonRatedIssues: {
        [Object.keys(state.nonRatedIssues).length]: {
          $set: {
            issueCategory: null,
            issueDescription: null
          }
        }
      }
    });
  case ACTIONS.SET_ISSUE_CATEGORY:
    return update(state, {
      nonRatedIssues: {
        [action.payload.issueId]: {
          $set: {
            issueCategory: action.payload.category,
            issueDescription: state.nonRatedIssues[action.payload.issueId].issueDescription
          }
        }
      }
    });
  case ACTIONS.SET_ISSUE_DESCRIPTION:
    return update(state, {
      nonRatedIssues: {
        [action.payload.issueId]: {
          $set: {
            issueCategory: state.nonRatedIssues[action.payload.issueId].issueCategory,
            issueDescription: action.payload.description
          }
        }
      }
    });
  default:
    return state;
  }
};
