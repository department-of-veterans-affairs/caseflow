/* eslint-disable no-unused-vars */

import PropTypes from 'prop-types';
import React, { useState, useContext } from 'react';
import classnames from 'classnames';

import { EmptyConfirmContext, EmptyConfirmMessageContext } from '../HearingTypeConversion';
import { OriginalEmailContext } from './VSOEmailNotificationsFields';
import { BtnContext } from '../VSOHearingTypeConversionForm';
import { HelperText } from '../VirtualHearings/HelperText';
import { enablePadding } from '../details/style';
import COPY from '../../../../COPY';
import TextField from '../../../components/TextField';

export const VSOHearingEmail = ({
  email,
  label,
  required,
  disabled,
  optional,
  helperLabel,
  showHelper,
  confirmEmail
}) => {

  const [message, setMessage] = useState('');
  const [isNotValidEmail, setIsNotValidEmail] = useContext(BtnContext);
  const [confirmIsEmptyMessage, setConfirmIsEmptyMessage] = useContext(EmptyConfirmMessageContext);
  const [originalEmail, setOriginalEmail] = useContext(OriginalEmailContext);
  const [confirmIsEmpty, setConfirmIsEmpty] = useContext(EmptyConfirmContext);

  // Regex to validate email input in real time
  const emailRegex = /\S+@\S+\.\S+/;

  const validateEmail = (newEmail) => {

    setOriginalEmail(newEmail);

    if (emailRegex.test(newEmail)) {
      setMessage('');
      setIsNotValidEmail(false);
    } else {
      setMessage('Please enter a valid email');
      setIsNotValidEmail(true);
    }
  };

  const confirmEmailCheck = (newEmail) => {

    if (newEmail === '') {
      setConfirmIsEmpty(true);
    } else {
      setConfirmIsEmpty(false);
    }

    if (newEmail === originalEmail) {
      setMessage('');
      setIsNotValidEmail(false);
    } else {
      setMessage('Email does not match');
      setIsNotValidEmail(true);
    }
  };

  return (
    confirmEmail ? (
      <React.Fragment>
        <TextField
          optional={optional}
          readOnly={disabled}
          errorMessage={confirmIsEmpty ? confirmIsEmptyMessage : message}
          name={label}
          value={email}
          required={!disabled && required}
          strongLabel
          className={[
            classnames('cf-form-textinput', 'cf-inline-field', {
              [enablePadding]: message,
            }),
          ]}
          onChange={(newEmail) => {
            confirmEmailCheck(newEmail);
          }}
        />
        {showHelper ? <HelperText label={helperLabel} /> : null}

      </React.Fragment>
    ) : (
      <React.Fragment>
        <TextField
          optional={optional}
          readOnly={disabled}
          errorMessage={message}
          name={label}
          value={email}
          required={!disabled && required}
          strongLabel
          className={[
            classnames('cf-form-textinput', 'cf-inline-field', {
              [enablePadding]: message,
            }),
          ]}
          onChange={(newEmail) => {
            validateEmail(newEmail);
          }}
        />
        {showHelper ? <HelperText label={helperLabel} /> : null}

      </React.Fragment>
    )
  );
};
VSOHearingEmail.defaultProps = {
  helperLabel: COPY.VIRTUAL_HEARING_EMAIL_HELPER_TEXT,
  showHelper: true,
};

VSOHearingEmail.propTypes = {
  email: PropTypes.string,
  emailType: PropTypes.string,
  label: PropTypes.string,
  readOnly: PropTypes.bool,
  error: PropTypes.string,
  update: PropTypes.func,
  required: PropTypes.bool,
  optional: PropTypes.bool,
  disabled: PropTypes.bool,
  helperLabel: PropTypes.string,
  showHelper: PropTypes.bool,
  confirmEmail: PropTypes.bool
};
