import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { analyticsCallback, submitIntakeCompleteRequest } from './intake';
import { validateReviewData, prepareReviewData } from '../util';
import { formatIssues } from '../util/issues';

const analytics = true;

export const submitReview = (intakeId, intakeData, intakeType) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START,
    meta: { analytics }
  });

  // const validationErrors = validateReviewData(intakeData, intakeType);

  // if (validationErrors) {
  //   dispatch({
  //     type: ACTIONS.SUBMIT_REVIEW_FAIL,
  //     payload: { responseErrorCodes: validationErrors },
  //     meta: { analytics }
  //   });

  //   return Promise.reject();
  // }

  const data = prepareReviewData(intakeData, intakeType);

  return ApiUtil.patch(`/intake/${intakeId}/review`, { data }, ENDPOINT_NAMES.REVIEW_INTAKE).then(
    (response) => {
      dispatch({
        type: ACTIONS.SUBMIT_REVIEW_SUCCEED,
        payload: {
          intake: response.body
        },
        meta: { analytics }
      });

      return true;
    },
    (error) => {
      const responseObject = error.response.body;
      const responseErrorCodes = responseObject.error_codes;

      dispatch({
        type: ACTIONS.SUBMIT_REVIEW_FAIL,
        payload: {
          errorUUID: responseObject.error_uuid,
          responseErrorCodes
        },
        meta: {
          analytics: analyticsCallback
        }
      });

      throw error;
    }
  );
};

export const completeIntake = (intakeId, intakeData) => (dispatch) => {
  dispatch({
    type: ACTIONS.COMPLETE_INTAKE_START,
    meta: { analytics }
  });

  const data = formatIssues(intakeData);

  return submitIntakeCompleteRequest(intakeId, { data })(dispatch);
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

export const setClaimant = (updates) => ({
  type: ACTIONS.SET_CLAIMANT,
  payload: {
    ...updates
  }
});

export const setPayeeCode = (payeeCode) => ({
  type: ACTIONS.SET_PAYEE_CODE,
  payload: {
    payeeCode
  }
});

export const setIssueSelected = (approxDecisionDate, issueId, isSelected) => ({
  type: ACTIONS.SET_ISSUE_SELECTED,
  payload: {
    approxDecisionDate,
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
