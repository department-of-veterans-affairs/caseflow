/* eslint-disable no-unused-vars */

import PropTypes from 'prop-types';
import React, { useState, useContext, useEffect } from 'react';
import classnames from 'classnames';

import HearingTypeConversionContext from '../../contexts/HearingTypeConversionContext';
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
  confirmEmail,
  emailType
}) => {
  const {
    setIsNotValidEmail,
    setEmailsMismatch,
    originalEmail,
    setOriginalEmail,
    setConfirmIsEmpty,
    confirmIsEmpty,
    updatedAppeal,
    dispatchAppeal
  } = useContext(HearingTypeConversionContext);

  const [message, setMessage] = useState('');

  // Regex to validate email input in real time
  const emailRegex = /\S+@\S+\.\S+/;

  const validateEmail = (newEmail, unFocused) => {

    setOriginalEmail(newEmail);

    if (emailRegex.test(newEmail)) {
      setMessage('');
      setIsNotValidEmail(false);
    } else if (unFocused) {
      // Only display error message if field focus is exited.
      setMessage(COPY.CONVERT_HEARING_VALIDATE_EMAIL);
      setIsNotValidEmail(true);
    } else {
      setIsNotValidEmail(true);
    }
  };

  const confirmEmailCheck = (newEmail, unFocused) => {

    if (newEmail === '') {
      setConfirmIsEmpty(true);
    } else {
      setConfirmIsEmpty(false);
    }

    if (newEmail === originalEmail) {
      setMessage('');
      setEmailsMismatch(false);
    } else if (unFocused) {
      // Only display error message if field focus is exited.
      if (newEmail && !confirmIsEmpty) {
        setMessage(COPY.CONVERT_HEARING_VALIDATE_EMAIL_MATCH);
      }
      setEmailsMismatch(true);
    } else {
      setEmailsMismatch(true);
    }
  };

  // Rerun original-to-confirmation email matching if original email changes
  useEffect(() => {
    if (confirmEmail) {
      confirmEmailCheck(updatedAppeal.appellantConfirmEmailAddress, true);
    }
  }, [originalEmail]);

  return (
    confirmEmail ? (
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
            confirmEmailCheck(newEmail, false);
            dispatchAppeal({ type: 'SET_APPELLANT_CONFIRM_EMAIL', payload: newEmail });
          }}
          onBlur={(newEmail) => {
            confirmEmailCheck(newEmail, true);
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
            dispatchAppeal({
              type: emailType === 'appellantEmailAddress' ?
                'SET_APPELLANT_EMAIL' :
                'SET_POA_EMAIL',
              payload: newEmail });
            validateEmail(newEmail, false);
          }}
          onBlur={(newEmail) => {
            validateEmail(newEmail, true);
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
