import React from 'react';
import PropTypes from 'prop-types';
import { useForm } from 'react-hook-form';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { CheckoutButtons } from './CheckoutButtons';

export const DocketSwitchReviewRequestForm = ({ onSubmit, onCancel }) => {
  const { handleSubmit, formState } = useForm({
    // add yup validation, etc
    // See DocketSwitchDenialForm for inspiration
  });

  return (
    <>
      <AppSegment filledBackground>
        {/* This should go into COPY.json */}
        <h1>Review Request</h1>

        {/* Add <form> and form fields */}
      </AppSegment>
      <CheckoutButtons
        disabled={!formState.isValid}
        onCancel={onCancel}
        onSubmit={handleSubmit(onSubmit)}
      />
    </>
  );
};

DocketSwitchReviewRequestForm.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
