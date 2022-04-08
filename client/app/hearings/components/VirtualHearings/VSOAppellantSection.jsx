import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { sprintf } from 'sprintf-js';

import COPY from '../../../../COPY';
import Alert from '../../../components/Alert';
import { AddressLine } from '../details/Address';
import { VirtualHearingSection } from './Section';
import { HelperText } from './HelperText';
import { HearingEmail } from '../details/HearingEmail';
import { Timezone } from './Timezone';
import { marginTop } from '../details/style';
import { ReadOnly } from '../details/ReadOnly';
import { VSOEmailNotificationsFields } from '../details/VSOEmailNotificationsFields.jsx'; 

export const VSOAppellantSection = ({
  hearing,
  errors,
  type,
  readOnly,
  fullWidth,
  showDivider,
  update,
  appellantTitle,
  showOnlyAppellantName,
  showMissingEmailAlert,
  showTimezoneField,
  schedulingToVirtual,
  formFieldsOnly,
  appellantTimezone,
  appellantEmailAddress,
  appellantEmailType
}) => {
  // Depending on where this component is used, the *FullName fields will be available.
  // If they aren't, the *FirstName/*LastName fields should be available.
  const appellantName = hearing?.appellantIsNotVeteran ?
    (hearing?.appellantFullName || `${hearing?.appellantFirstName} ${hearing?.appellantLastName}`) :
    (hearing?.veteranFullName || `${hearing?.veteranFirstName} ${hearing?.veteranLastName}`);

  // determine whether to show a missing email underneath readonly email
  const showMissingAlert = readOnly && showMissingEmailAlert && !hearing?.appellantEmailAddress;

  // Set the grid column width to respect fullWidth prop
  const columnWidthClass = fullWidth ? 'usa-width-one-whole' : 'usa-width-one-half';

  return (
    <VirtualHearingSection formFieldsOnly={formFieldsOnly} label={appellantTitle} showDivider={showDivider}>
      <React.Fragment>
        <ReadOnly
              label={`${appellantTitle} Name`}
              text={appellantName}
        />
        <VSOEmailNotificationsFields veteran={true}/>
      </React.Fragment>
    </VirtualHearingSection>
  );
};

VSOAppellantSection.defaultProps = {
  schedulingToVirtual: true
};

VSOAppellantSection.propTypes = {
  hearing: PropTypes.object,
  errors: PropTypes.object,
  type: PropTypes.string,
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  fullWidth: PropTypes.bool,
  appellantTitle: PropTypes.string,
  showOnlyAppellantName: PropTypes.bool,
  showDivider: PropTypes.bool,
  showMissingEmailAlert: PropTypes.bool,
  showTimezoneField: PropTypes.bool,
  virtual: PropTypes.bool,
  userCanCollectVideoCentralEmails: PropTypes.bool,
  schedulingToVirtual: PropTypes.bool,
  formFieldsOnly: PropTypes.bool,
  appellantTimezone: PropTypes.string,
  appellantEmailAddress: PropTypes.string,
  appellantEmailType: PropTypes.string
};
