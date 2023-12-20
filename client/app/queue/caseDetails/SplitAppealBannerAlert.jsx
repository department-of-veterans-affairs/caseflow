import React from 'react';
import PropTypes from 'prop-types';
// import { useSelector } from 'react-redux';
import COPY from '../../../COPY.json';
import Alert from 'app/components/Alert';
import { sprintf } from 'sprintf-js';

export const SplitAppealBannerAlert = (props) => (
  <Alert
    type= {props.splitAppealSuccess ? 'success' : 'error'}
    title= {props.splitAppealSuccess ?
      sprintf(COPY.SPLIT_APPEAL_BANNER_SUCCESS_TITLE, { appellantName: 'Abellona Valtas' }) :
      'Unable to Process Request'}
    message= {props.splitAppealSuccess ?
      COPY.SPLIT_APPEAL_BANNER_SUCCESS_MESSAGE :
      'Something went wrong and the appeal was not split'}
    {...props}
  />
);

SplitAppealBannerAlert.propTypes = {
  splitAppealSuccess: PropTypes.bool,
  workflow: PropTypes.bool
};
