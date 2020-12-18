import React from 'react';
import PropTypes from 'prop-types';

import CancelButton from 'app/intake/components/CancelButton';
import Button from 'app/components/Button';

const NextButton = ({ disabled, loading, onClick }) => {
  return (
    <Button
      name="submit-review"
      onClick={onClick}
      loading={loading}
      disabled={disabled}
    >
      Continue to next step
    </Button>
  );
};

NextButton.propTypes = {
  disabled: PropTypes.bool,
  loading: PropTypes.bool,
  onClick: PropTypes.func,
};

export const AddClaimantButtons = ({ onSubmit, isValid }) => {
  return (
    <div>
      <CancelButton />
      <NextButton onClick={onSubmit} disabled={!isValid} />
    </div>
  );
};

AddClaimantButtons.propTypes = {
  isValid: PropTypes.bool,
  onSubmit: PropTypes.func,
};
