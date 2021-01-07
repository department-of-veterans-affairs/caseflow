import React from 'react';
import PropTypes from 'prop-types';

import CancelButton from 'app/intake/components/CancelButton';
import Button from 'app/components/Button';

const BackButton = ({ onClick }) => (
  <Button
    type="button"
    name="go-back"
    onClick={onClick}
    classNames={['usa-button-secondary']}
    styling={{ style: { marginRight: '1em' } }}
  >
    Back
  </Button>
);

BackButton.propTypes = {
  onClick: PropTypes.func,
};

const NextButton = ({ ...btnProps }) => {
  return (
    <Button name="submit-review" {...btnProps}>
      Continue to next step
    </Button>
  );
};

NextButton.propTypes = {
  disabled: PropTypes.bool,
  loading: PropTypes.bool,
  onClick: PropTypes.func,
};

export const AddClaimantButtons = ({ onBack, onSubmit, isValid }) => {
  return (
    <div>
      <CancelButton
        classNames={['cf-btn-link']}
        styling={{ style: { float: 'left', paddingLeft: 0 } }}
      />
      <BackButton onClick={() => onBack?.()} />
      <NextButton
        onClick={onSubmit}
        disabled={!isValid}
        classNames={['cf-right-side']}
      />
    </div>
  );
};

AddClaimantButtons.propTypes = {
  isValid: PropTypes.bool,
  onBack: PropTypes.func,
  onSubmit: PropTypes.func,
};
