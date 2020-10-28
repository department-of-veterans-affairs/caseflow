import React from 'react';
import PropTypes from 'prop-types';
import Alert from 'app/components/Alert';

const CannotSaveAlert = ({ message }) => {

  const messages = ['Unable to save.'];

  // eslint-disable-next-line babel/no-unused-expressions
  message ? messages.push(message) : messages.push('Please try again.');

  return <Alert type="error" message={messages.join(' ')} />;
};

CannotSaveAlert.propTypes = {
  message: PropTypes.node
};

export default CannotSaveAlert;
