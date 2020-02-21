import {
  JUDGE_ADDRESS_MTV_SUCCESS_TITLE_GRANTED,
  JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_GRANTED,
  JUDGE_ADDRESS_MTV_SUCCESS_TITLE_DENIED,
  JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_DENIED
} from '../../../COPY';
import { sprintf } from 'sprintf-js';

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
