/* eslint-disable no-unused-vars */

import PropTypes from 'prop-types';
import React, { useState, useEffect } from 'react';
import classnames from 'classnames';

import { HelperText } from '../VirtualHearings/HelperText';
import { enablePadding } from '../details/style';
import COPY from '../../../../COPY';
import TextField from '../../../components/TextField';

export const VSOHearingEmail = ({
  hearing,
  email,
  label,
  required,
  disabled,
  optional,
  helperLabel,
  showHelper,
  confirmEmail,
  emailType,
  actionType,
  setIsValidEmail,
  update
}) => {

  const [message, setMessage] = useState('');

  // Regex to validate email input in real time
  // eslint-disable-next-line max-len
  const emailRegex = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

  const validateEmail = (newEmail, unFocused) => {
    if (emailRegex.test(newEmail)) {
      setMessage('');
      setIsValidEmail(true);
    } else if (unFocused) {
      // Only display error message if field focus is exited.
      setMessage(COPY.CONVERT_HEARING_VALIDATE_EMAIL);
      setIsValidEmail(false);
    } else {
      setIsValidEmail(false);
    }
  };

  const confirmEmailCheck = (newEmail, unFocused) => {
    if (newEmail === hearing?.appellantEmailAddress) {
      setMessage('');
    } else if (unFocused && newEmail) {
      setMessage(COPY.CONVERT_HEARING_VALIDATE_EMAIL_MATCH);
    }
  };

  // Rerun original-to-confirmation email matching if original email changes
  useEffect(() => {
    if (confirmEmail) {
      confirmEmailCheck(hearing?.appellantConfirmEmailAddress, true);
    }
  }, [hearing?.appellantEmailAddress]);

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
          onChange={(appellantConfirmEmailAddress) => {
            confirmEmailCheck(appellantConfirmEmailAddress, false);
            update(actionType, { appellantConfirmEmailAddress });
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
            update(actionType, { [emailType]: newEmail });
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
  confirmEmail: false
};

VSOHearingEmail.propTypes = {
  hearing: PropTypes.object,
  email: PropTypes.string,
  emailType: PropTypes.string,
  label: PropTypes.string,
  required: PropTypes.bool,
  optional: PropTypes.bool,
  disabled: PropTypes.bool,
  helperLabel: PropTypes.string,
  showHelper: PropTypes.bool,
  confirmEmail: PropTypes.bool,
  update: PropTypes.func,
  actionType: PropTypes.string,
  setIsValidEmail: PropTypes.func
};
