import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import DecisionViewFooter from 'app/queue/components/DecisionViewFooter';

export const CheckoutButtons = ({
  onCancel,
  onBack,
  onSubmit,
  disabled = false,
}) => {
  const cancelBtn = {
    classNames: ['cf-btn-link'],
    callback: onCancel,
    name: 'cancel-button',
    displayText: 'Cancel',
    willNeverBeLoading: true,
  };

  const backBtn = {
    classNames: ['cf-right-side'],
    callback: onSubmit,
    name: 'next-button',
    disabled,
    displayText: 'Continue',
    styling: css({ marginLeft: '1rem' }),
  };

  const submitBtn = {
    classNames: ['cf-right-side', 'cf-prev-step', 'usa-button-secondary'],
    callback: onBack ?? onCancel,
    name: 'back-button',
    displayText: onBack ? 'Back' : 'Cancel',
    willNeverBeLoading: true,
  };

  // Button layout from QueueFlowPage
  const buttons = useMemo(() => [
    // Only display left-side cancel if we have a back button
    ...(onBack ? [cancelBtn] : []),
    backBtn,
    submitBtn,
  ]);

  return <DecisionViewFooter buttons={buttons} />;
};
CheckoutButtons.propTypes = {
  disabled: PropTypes.bool,
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};

export default CheckoutButtons;
