import PropTypes from 'prop-types';
import React, { useState, useContext } from 'react';
import { isEmpty } from 'lodash';
import classnames from 'classnames';
import * as yup from 'yup';

import { EmptyConfirmContext, EmptyConfirmMessageContext } from '../HearingTypeConversion';
import { OriginalEmailContext } from './VSOEmailNotificationsFields';
import { BtnContext } from '../VSOHearingTypeConversionForm';
import { HelperText } from '../VirtualHearings/HelperText';
import { ReadOnly } from '../details/ReadOnly';
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
  const [isValid, setIsValid] = useState(false);
  const [message, setMessage] = useState('');

  const [isNotValidEmail, setIsNotValidEmail] = useContext(BtnContext);
  const [originalEmail, setOriginalEmail] = useContext(OriginalEmailContext);
  const [confirmIsEmpty, setConfirmIsEmpty] = useContext(EmptyConfirmContext);
  const [confirmIsEmptyMessage, setConfirmIsEmptyMessage] = useContext(EmptyConfirmMessageContext);

  // Regex to validate email input in real time
  const emailRegex = /\S+@\S+\.\S+/;

  const validateEmail = (newEmail) => {
    const email = newEmail;

    setOriginalEmail(email);

    if (emailRegex.test(email)) {
      setIsValid(true);
      setMessage('');
      setIsNotValidEmail(false);
    } else {
      setIsValid(false);
      setMessage('Please enter a valid email');
      setIsNotValidEmail(true);
    }
  };

  const confirmEmailCheck = (newEmail) => {
    const email = newEmail;

    if (email === '') {
      setConfirmIsEmpty(true);
    } else {
      setConfirmIsEmpty(false);
    }

    if (email === originalEmail) {
      setIsValid(true);
      setMessage('');
      setIsNotValidEmail(false);
    } else {
      setIsValid(false);
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
