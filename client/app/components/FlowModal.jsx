import React, { useState, useEffect } from 'react';
import Modal from './Modal';
import Alert from './Alert';
import COPY from '../../COPY';
import PropTypes from 'prop-types';
import { highlightInvalidFormItems } from '../queue/uiReducer/uiActions';

const FlowModal = ({
  title = '',
  button = COPY.MODAL_SUBMIT_BUTTON,
  children,
  error,
  success,
  submitDisabled = false,
  submitButtonClassNames = ['usa-button', 'usa-button-hover', 'usa-button-warning'],
  pathAfterSubmit = '/queue',
  history,
  onCancel,
  submit,
  validateForm,
  saveSuccessful,
  resetSaveState
}) => {
  const [loading, setLoading] = useState(false);
  const [pathAfterSubmitState] = useState(pathAfterSubmit);
  const [submitSuccess, setSubmitSuccess] = useState(null);

  useEffect(() => {
    if (highlightInvalidFormItems) {
      highlightInvalidFormItems(false);
    }
  }, [highlightInvalidFormItems]);

  const cancelHandler = () => onCancel ? onCancel() : history.goBack();

  const closeHandler = () => history.replace(pathAfterSubmitState);

  const handleSubmit = () => {
    if (validateForm && !validateForm()) {
      return highlightInvalidFormItems(true);
    }

    if (highlightInvalidFormItems) {
      highlightInvalidFormItems(false);
    }

    setLoading(true);

    submit().
      then(() => {
        setSubmitSuccess(saveSuccessful);
      }).
      finally(() => {
        resetSaveState();
        setLoading(false);
      });
  };

  useEffect(() => {
    if (submitSuccess) {
      closeHandler();
    }
  }, [submitSuccess]);

  return (
    <Modal
      title={title}
      buttons={[
        {
          classNames: ['usa-button', 'cf-btn-link'],
          name: COPY.MODAL_CANCEL_BUTTON,
          onClick: cancelHandler
        },
        {
          classNames: submitButtonClassNames,
          name: button,
          disabled: submitDisabled,
          loading,
          onClick: handleSubmit
        }
      ]}
      closeHandler={cancelHandler}
    >
      {error && <Alert title={error.title} type="error">{error.detail}</Alert>}
      {success && <Alert title={success.title} type="success">{success.detail}</Alert>}
      {children}
    </Modal>
  );
};

FlowModal.propTypes = {
  children: PropTypes.node,
  highlightInvalidFormItems: PropTypes.func,
  history: PropTypes.object,
  title: PropTypes.string,
  button: PropTypes.string,
  onCancel: PropTypes.func,
  pathAfterSubmit: PropTypes.string,
  // submit should return a promise on which .then() can be called
  submit: PropTypes.func,
  submitDisabled: PropTypes.bool,
  validateForm: PropTypes.func,
  saveSuccessful: PropTypes.bool,
  success: PropTypes.object,
  error: PropTypes.object,
  resetSaveState: PropTypes.func,
  submitButtonClassNames: PropTypes.arrayOf(
    PropTypes.string
  )
};

export default FlowModal;
