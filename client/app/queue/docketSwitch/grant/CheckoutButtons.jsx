import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import cx from 'classnames';
import DecisionViewFooter from 'app/queue/components/DecisionViewFooter';
export const CheckoutButtons = ({
  onCancel,
  onBack,
  onSubmit,
  disabled = false,
}) => {
  const cancelBtn = {
    classNames: [cx('cf-btn-link', { 'cf-right-side': !onBack })],
    callback: onCancel,
    name: 'cancel-button',
    displayText: 'Cancel',
    willNeverBeLoading: true,
  };
  const submitBtn = {
    classNames: ['cf-right-side'],
    callback: onSubmit,
    name: 'next-button',
    disabled,
    displayText: 'Continue',
    styling: css({ marginLeft: '1rem' }),
  };
  const backBtn = {
    classNames: ['cf-right-side', 'cf-prev-step', 'usa-button-secondary'],
    callback: onBack,
    name: 'back-button',
    displayText: 'Back',
    willNeverBeLoading: true,
  };
  // Button layout from QueueFlowPage
  const buttons = useMemo(() => [
    submitBtn,
    cancelBtn,
    // Only display "Back" button if applicable
    ...(onBack ? [backBtn] : []),
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
