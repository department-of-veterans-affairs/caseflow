import React from 'react';
import PropTypes from 'prop-types';
// import { useSelector } from 'react-redux';
import COPY from '../../../COPY.json';
import Alert from 'app/components/Alert';

export const SplitAppealBannerAlert = (props) => (
  (props.splitAppealSuccess && props.workflow) &&
    <Alert
      type="success"
      title={COPY.SPLIT_APPEAL_BANNER_SUCCESS_TITLE}
      message={COPY.SPLIT_APPEAL_BANNER_SUCCESS_MESSAGE}
      {...props}
    />
);

SplitAppealBannerAlert.propTypes = {
  splitAppealSuccess: PropTypes.bool,
  workflow: PropTypes.bool
};
