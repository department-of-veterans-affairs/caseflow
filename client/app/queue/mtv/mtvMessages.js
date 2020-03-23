import {
  MOTIONS_ATTORNEY_REVIEW_MTV_SUCCESS_TITLE,
  MOTIONS_ATTORNEY_REVIEW_MTV_SUCCESS_DETAIL,
  JUDGE_ADDRESS_MTV_SUCCESS_TITLE_GRANTED,
  JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_GRANTED,
  JUDGE_ADDRESS_MTV_SUCCESS_TITLE_DENIED,
  JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_DENIED,
  RETURN_TO_LIT_SUPPORT_SUCCESS_TITLE,
  RETURN_TO_LIT_SUPPORT_SUCCESS_DETAIL,
  MTV_CHECKOUT_RETURN_TO_JUDGE_SUCCESS_TITLE,
  MTV_CHECKOUT_RETURN_TO_JUDGE_SUCCESS_DETAILS
} from '../../../COPY';
import { sprintf } from 'sprintf-js';

export const reviewMotionToVacateSuccessAlert = ({ judge = {} }) => {
  const { display_name: judgeName } = judge;

  return {
    title: sprintf(MOTIONS_ATTORNEY_REVIEW_MTV_SUCCESS_TITLE, judgeName || 'the judge'),
    detail: MOTIONS_ATTORNEY_REVIEW_MTV_SUCCESS_DETAIL
  };
};

export const addressMTVSuccessAlert = ({ data, appeal }) => {
  const { disposition } = data;
  const { veteranFullName } = appeal;

  switch (disposition) {
  case 'granted':
  case 'partially_granted':
    return {
      title: sprintf(JUDGE_ADDRESS_MTV_SUCCESS_TITLE_GRANTED, veteranFullName),
      detail: sprintf(JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_GRANTED)
    };
  case 'denied':
  case 'dismissed':
    return {
      title: sprintf(JUDGE_ADDRESS_MTV_SUCCESS_TITLE_DENIED, veteranFullName, disposition),
      detail: JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_DENIED
    };
  default:
    return {
      title: 'Task Complete',
      detail: ' '
    };
  }
};

export const returnToLitSupportAlert = ({ appeal }) => {
  const { veteranFullName } = appeal;

  return {
    title: sprintf(RETURN_TO_LIT_SUPPORT_SUCCESS_TITLE, veteranFullName),
    detail: RETURN_TO_LIT_SUPPORT_SUCCESS_DETAIL
  };
};

export const returnToJudgeAlert = ({ appeal, judge }) => {
  const { veteranFullName } = appeal;

  return {
    title: sprintf(MTV_CHECKOUT_RETURN_TO_JUDGE_SUCCESS_TITLE, veteranFullName, judge.full_name),
    detail: MTV_CHECKOUT_RETURN_TO_JUDGE_SUCCESS_DETAILS
  };
};
