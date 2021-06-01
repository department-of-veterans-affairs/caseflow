// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import Alert from 'app/components/Alert';

/**
 * Cannot Save Alert Component
 * @param {Object} props -- Contains the optional message and default message
 */
export const CannotSaveAlert = ({ defaultMessage, message }) => {
  // Set the messages
  const messages = message ? [defaultMessage, message] : [defaultMessage, 'Please try again.'];

  return <Alert type="error" message={messages.join(' ')} />;
};

CannotSaveAlert.defaultProps = {
  defaultMessage: 'Unable to save.'
};

CannotSaveAlert.propTypes = {
  defaultMessage: PropTypes.string,
  message: PropTypes.string
};
