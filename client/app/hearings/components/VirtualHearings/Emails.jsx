import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';

import {
  fullWidth,
  enablePadding,
  maxWidthFormInput,
} from '../details/style';
import TextField from '../../../components/TextField';
import { ReadOnly } from '../details/ReadOnly';
import { HelperText } from './HelperText';
import COPY from '../../../../COPY';

export const VirtualHearingEmail = ({ email, emailType, label, readOnly, error, update, required, disabled }) =>
  readOnly ? (
    <ReadOnly label={label}>
      <span {...fullWidth}>{email}</span>
    </ReadOnly>
  ) : (
    <React.Fragment>
      <TextField
        readOnly={disabled}
        errorMessage={error}
        name={label}
        value={email}
        required={required}
        strongLabel
        className={[
          classnames('cf-form-textinput', 'cf-inline-field', {
            [enablePadding]: error,
          }),
        ]}
        onChange={(newEmail) =>
          update('virtualHearing', { [emailType]: newEmail })
        }
        inputStyling={maxWidthFormInput}
      />
      <HelperText label={COPY.VIRTUAL_HEARING_EMAIL_HELPER_TEXT} />
    </React.Fragment>
  );

VirtualHearingEmail.propTypes = {
  email: PropTypes.string,
  emailType: PropTypes.string,
  label: PropTypes.string,
  readOnly: PropTypes.bool,
  error: PropTypes.string,
  update: PropTypes.func,
  required: PropTypes.bool,
  disabled: PropTypes.bool,
};
