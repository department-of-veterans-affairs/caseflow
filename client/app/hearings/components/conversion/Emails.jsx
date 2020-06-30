import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';

import {
  fullWidth,
  enablePadding,
  maxWidthFormInput,
} from '../details/style';
import TextField from '../../../components/TextField';
import { HelperText, DisplayValue, LeftAlign } from '.';
import COPY from '../../../../COPY';

export const VirtualHearingEmail = ({ email, label, type, error, update, required }) =>
  type === 'change_from_virtual' ? (
    <DisplayValue label={label}>
      <span {...fullWidth}>{email}</span>
    </DisplayValue>
  ) : (
    <React.Fragment>
      <LeftAlign>
        <TextField
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
          onChange={(appellantEmail) =>
            update('virtualHearing', { appellantEmail })
          }
          inputStyling={maxWidthFormInput}
        />
      </LeftAlign>
      <HelperText label={COPY.VIRTUAL_HEARING_EMAIL_HELPER_TEXT} />
    </React.Fragment>
  );
