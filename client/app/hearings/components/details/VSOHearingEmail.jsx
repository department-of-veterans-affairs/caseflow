import PropTypes from 'prop-types';
import React from 'react';
import { isEmpty } from 'lodash';
import classnames from 'classnames';

import { ReadOnly } from '../details/ReadOnly';
import { enablePadding } from '../details/style';
import TextField from '../../../components/TextField';

export const VSOHearingEmail = ({
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
          update('hearing', {
            [emailType]: isEmpty(newEmail) ? null : newEmail,
          })
        }
      />
      
    </React.Fragment>
  );

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
};
