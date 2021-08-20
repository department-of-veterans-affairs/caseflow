import PropTypes from 'prop-types';
import React from 'react';
import { isEmpty } from 'lodash';
import classnames from 'classnames';

import { HelperText } from './HelperText';
import { ReadOnly } from '../details/ReadOnly';
import { enablePadding } from '../details/style';
import COPY from '../../../../COPY';
import TextField from '../../../components/TextField';

export const VirtualHearingEmail = ({
  email,
  emailType,
  label,
  readOnly,
  error,
  update,
  required,
  disabled,
  optional,
}) =>
  readOnly ? (
    <ReadOnly label={label} text={email ?? 'None'} />
  ) : (
    <React.Fragment>
      <TextField
        optional={optional}
        readOnly={disabled}
        errorMessage={error}
        name={label}
        value={email}
        required={!disabled && required}
        strongLabel
        className={[
          classnames('cf-form-textinput', 'cf-inline-field', {
            [enablePadding]: error,
          }),
        ]}
        onChange={(newEmail) =>
          update('virtualHearing', {
            [emailType]: isEmpty(newEmail) ? null : newEmail,
          })
        }
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
  optional: PropTypes.bool,
  disabled: PropTypes.bool,
};
