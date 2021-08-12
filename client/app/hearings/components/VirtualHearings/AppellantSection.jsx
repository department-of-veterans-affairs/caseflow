import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { sprintf } from 'sprintf-js';

import COPY from '../../../../COPY';
import Alert from '../../../components/Alert';
import { AddressLine } from '../details/Address';
import { VirtualHearingSection } from './Section';
import { HelperText } from './HelperText';
import { VirtualHearingEmail } from './Emails';
import { Timezone } from './Timezone';
import { marginTop } from '../details/style';
import { ReadOnly } from '../details/ReadOnly';

export const AppellantSection = ({
  hearing,
  virtualHearing,
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
  userCanCollectVideoCentralEmails,
  virtual
}) => {
  // Depending on where this component is used, the *FullName fields will be available.
  // If they aren't, the *FirstName/*LastName fields should be available.
  const appellantName = hearing?.appellantIsNotVeteran ?
    (hearing?.appellantFullName || `${hearing?.appellantFirstName} ${hearing?.appellantLastName}`) :
    (hearing?.veteranFullName || `${hearing?.veteranFirstName} ${hearing?.veteranLastName}`);

  // determine whether to show a missing email underneath readonly email
  const showMissingAlert = readOnly && showMissingEmailAlert && !virtualHearing?.appellantEmail;

  // Set the grid column width to respect fullWidth prop
  const columnWidthClass = fullWidth ? 'usa-width-one-whole' : 'usa-width-one-half';

  return (
    <VirtualHearingSection label={appellantTitle} showDivider={showDivider}>
      {/*
        * Appellant Name and Address
        */}
      {showOnlyAppellantName ? (
        <ReadOnly
          label={`${appellantTitle} Name`}
          text={appellantName}
        />
      ) :
        (
          <React.Fragment>
            <ReadOnly
              label={`${appellantTitle} Name`}
              text={appellantName}
            />
            {hearing?.appellantIsNotVeteran && hearing?.appellantRelationship && (
              <ReadOnly
                label="Relation to Veteran"
                text={hearing?.appellantRelationship}
              />
            )}
            <AddressLine
              label={`${appellantTitle} Mailing Address`}
              name={appellantName}
              addressLine1={hearing?.appellantAddressLine1}
              addressState={hearing?.appellantState}
              addressCity={hearing?.appellantCity}
              addressZip={hearing?.appellantZip}
            />
          </React.Fragment>
        )}
      {/*
        * Timezone fields
        */}
      {showTimezoneField && (schedulingToVirtual || userCanCollectVideoCentralEmails) && (
        <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
          <div className={classNames(columnWidthClass)} >
            <Timezone
              required={virtual}
              optional={!virtual}
              value={virtualHearing?.appellantTz}
              onChange={(appellantTz) => update('virtualHearing', { appellantTz })}
              time={hearing?.scheduledTimeString}
              roTimezone={hearing?.regionalOfficeTimezone}
              label={`${appellantTitle} Timezone`}
              name="appellantTz"
              errorMessage={errors?.appellantTz}
            />
            <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
          </div>
        </div>
      )}
      {/*
        * Email fields
        */}
      <div id="email-section" className={classNames('usa-grid', { [marginTop(30)]: true })}>
        <div className={classNames(columnWidthClass)} >
          <VirtualHearingEmail
            required={virtual}
            optional={!virtual}
            readOnly={readOnly}
            label={`${appellantTitle} Email`}
            emailType="appellantEmail"
            email={virtualHearing?.appellantEmail}
            error={errors?.appellantEmail}
            type={type}
            update={update}
          />
          {showMissingAlert && (
            <div>
              <Alert
                message={sprintf(COPY.MISSING_EMAIL_ALERT_MESSAGE, appellantTitle)}
                type="info"
                scrollOnAlert={false}
              />
            </div>
          )}
        </div>
      </div>
    </VirtualHearingSection>
  );
};

AppellantSection.defaultProps = {
  schedulingToVirtual: true
};

AppellantSection.propTypes = {
  hearing: PropTypes.object,
  virtualHearing: PropTypes.object,
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
  schedulingToVirtual: PropTypes.bool
};
