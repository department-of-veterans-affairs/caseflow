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

  const validationErrors = validateReviewData(intakeData, intakeType);

  if (validationErrors) {
    dispatch({
      type: ACTIONS.SUBMIT_REVIEW_FAIL,
      payload: { responseErrorCodes: validationErrors },
      meta: { analytics }
    });

    return Promise.reject();
  }

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

export const submitReviewUnListedClaimant = (intakeId, intakeData, intakeType, claimant, poa) => (dispatch) => {
   dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START,
    meta: { analytics }
  });

  const validationErrors = validateReviewData(intakeData, intakeType);

  if (validationErrors) {
    dispatch({
      type: ACTIONS.SUBMIT_REVIEW_FAIL,
      payload: { responseErrorCodes: validationErrors },
      meta: { analytics }
    });

    return Promise.reject();
  }

const data = prepareReviewData(intakeData, intakeType);
data.unlisted_claimant = {
    relationship: claimant.relationship,
    party_type: claimant.partyType,
    first_name: claimant.firstName,
    middle_name: claimant.middleName,
    last_name: claimant.lastName,
    suffix: claimant.suffix,
    address_line_1: claimant.address1,
    address_line_2: claimant.address2,
    address_line_3: claimant.address3,
    city: claimant.city,
    state: claimant.state,
    zip: claimant.zip,
    country: claimant.country,
    phone_number: claimant.phoneNumber,
    email_address: claimant.email,
    poa_form: false}
data.unlisted_poa = { 
    party_type: poa.partyType,
    name: poa.name,
    address_line_1: poa.address1,
    address_line_2: poa.address2,
    address_line_3: poa.address3,
    city: poa.city,
    state: poa.state,
    zip: poa.zip,
    country: poa.country,
    phone_number: poa.phoneNumber,
    email_address: poa.email,
    listed_attorney: poa.listedAttorney
  }

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

}


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
