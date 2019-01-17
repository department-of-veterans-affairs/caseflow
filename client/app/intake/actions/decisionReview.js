import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { prepareReviewData } from '../util';
import { formatIssues } from '../util/issues';
import _ from 'lodash';

const analytics = true;

export const submitReview = (intakeId, intakeData, intakeType) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START,
    meta: { analytics }
  });

  const data = prepareReviewData(intakeData, intakeType);

  return ApiUtil.patch(`/intake/${intakeId}/review`, { data }, ENDPOINT_NAMES.REVIEW_INTAKE).
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.SUBMIT_REVIEW_SUCCEED,
          payload: {
            intake: responseObject
          },
          meta: { analytics }
        });

        return true;
      },
      (error) => {
        const responseObject = JSON.parse(error.response.text);
        const responseErrorCodes = responseObject.error_codes;

        dispatch({
          type: ACTIONS.SUBMIT_REVIEW_FAIL,
          payload: {
            responseErrorCodes
          },
          meta: {
            analytics: (triggerEvent, category, actionName) => {
              triggerEvent(category, actionName, 'any-error');

              _.forEach(
                responseErrorCodes,
                (errorVal, errorKey) => triggerEvent(category, actionName, `${errorKey}-${errorVal}`)
              );
            }
          }
        });
      }
    );
};

export const completeIntake = (intakeId, intakeData) => (dispatch) => {
  dispatch({
    type: ACTIONS.COMPLETE_INTAKE_START,
    meta: { analytics }
  });

  const data = formatIssues(intakeData);

  return ApiUtil.patch(`/intake/${intakeId}/complete`, { data }, ENDPOINT_NAMES.COMPLETE_INTAKE).
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.COMPLETE_INTAKE_SUCCEED,
          payload: {
            intake: responseObject
          },
          meta: { analytics }
        });

        return true;
      },
      (error) => {
        let responseObject = {};

        try {
          responseObject = JSON.parse(error.response.text);
        } catch (ex) { /* pass */ }

        const responseErrorCode = responseObject.error_code;
        const responseErrorData = responseObject.error_data;

        dispatch({
          type: ACTIONS.COMPLETE_INTAKE_FAIL,
          payload: {
            responseErrorCode,
            responseErrorData
          },
          meta: { analytics }
        });
        throw error;
      }
    );
};

export const setBenefitType = (benefitType) => ({
  type: ACTIONS.SET_BENEFIT_TYPE,
  payload: {
    benefitType
  }
});

export const setLegacyOptInApproved = (legacyOptInApproved) => ({
  type: ACTIONS.SET_LEGACY_OPT_IN_APPROVED,
  payload: {
    legacyOptInApproved
  }
});

export const setVeteranIsNotClaimant = (veteranIsNotClaimant) => ({
  type: ACTIONS.SET_VETERAN_IS_NOT_CLAIMANT,
  payload: {
    veteranIsNotClaimant
  }
});

export const setClaimant = (claimant) => ({
  type: ACTIONS.SET_CLAIMANT,
  payload: {
    claimant
  }
});

export const setPayeeCode = (payeeCode) => ({
  type: ACTIONS.SET_PAYEE_CODE,
  payload: {
    payeeCode
  }
});

export const setIssueSelected = (profileDate, issueId, isSelected) => ({
  type: ACTIONS.SET_ISSUE_SELECTED,
  payload: {
    profileDate,
    issueId,
    isSelected
  },
  meta: {
    analytics: {
      label: isSelected ? 'selected' : 'de-selected'
    }
  }
});

export const newNonratingRequestIssue = (nonRatingRequestIssues) => ({
  type: ACTIONS.NEW_NONRATING_REQUEST_ISSUE,
  payload: {
    nonRatingRequestIssues
  },
  meta: { analytics }
});

export const setIssueCategory = (issueId, category) => ({
  type: ACTIONS.SET_ISSUE_CATEGORY,
  payload: {
    issueId,
    category
  },
  meta: {
    analytics: {
      label: category
    }
  }
});

export const setIssueDescription = (issueId, description) => ({
  type: ACTIONS.SET_ISSUE_DESCRIPTION,
  payload: {
    issueId,
    description
  },
  meta: {
    analytics: {
      label: description
    }
  }
});

export const setIssueDecisionDate = (issueId, decisionDate) => ({
  type: ACTIONS.SET_ISSUE_DECISION_DATE,
  payload: {
    issueId,
    decisionDate
  },
  meta: {
    analytics: {
      label: decisionDate
    }
  }
});
