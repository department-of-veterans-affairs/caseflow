import * as React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';

const DispatchSuccessDetail = (props) => {
  const { task, feedbackUrl } = props;

  if (task.appealType === 'LegacyAppeal') {
    return COPY.CHECKOUT_DISPATCH_SUCCESS_DETAIL_LEGACY;
  }

  return <React.Fragment>
    {COPY.CHECKOUT_DISPATCH_SUCCESS_DETAIL_AMA_BEFORE_LINK}
    <a
      href={feedbackUrl}
      target="_blank"
      rel="noopener noreferrer"
    >
      {COPY.CHECKOUT_DISPATCH_SUCCESS_DETAIL_AMA_LINK}
    </a>
    {COPY.CHECKOUT_DISPATCH_SUCCESS_DETAIL_AMA_AFTER_LINK}
  </React.Fragment>;
};

DispatchSuccessDetail.propTypes = {
  task: PropTypes.shape({
    appealType: PropTypes.string.isRequired
  }).isRequired,
  feedbackUrl: PropTypes.string.isRequired
};

export default (
  connect((state) => ({ feedbackUrl: state.ui.feedbackUrl }))(DispatchSuccessDetail)
);
