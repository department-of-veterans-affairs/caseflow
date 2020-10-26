import React from 'react';
import PropTypes from 'prop-types';
import Alert from '../../components/Alert';

const CannotSaveAlert = ({ message }) => {

  let messages = ['Unable to save.'];

  if (message) {
    messages.push(message);
  } else {
    messages.push('Please try again.');
  }

  return <Alert type="error" message={messages.join(' ')} />;
};

CannotSaveAlert.propTypes = {
  message: PropTypes.node
};

export default React.memo(CannotSaveAlert);
