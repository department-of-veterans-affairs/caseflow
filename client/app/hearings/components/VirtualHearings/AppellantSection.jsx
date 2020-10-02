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
import { marginTop, noMaxWidth } from '../details/style';
import { ReadOnly } from '../details/ReadOnly';

export const AppellantSection = ({
  hearing,
  virtualHearing,
  errors,
  type,
  virtual,
  video,
  readOnly,
  showDivider,
  update,
  appellantTitle,
  showOnlyAppellantName,
  showMissingEmailAlert
}) => {
  // Depending on where this component is used, the *FullName fields will be available.
  // If they aren't, the *FirstName/*LastName fields should be available.
  const appellantName = hearing?.appellantIsNotVeteran ?
    (hearing?.appellantFullName || `${hearing?.appellantFirstName} ${hearing?.appellantLastName}`) :
    (hearing?.veteranFullName || `${hearing?.veteranFirstName} ${hearing?.veteranLastName}`);
  const showTimezoneField = virtual && !video;

  // determine whether to show a missing email underneath readonly email
  const showMissingAlert = readOnly && showMissingEmailAlert && !virtualHearing?.appellantEmail;

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
          <AddressLine
            name={appellantName}
            addressLine1={hearing?.appellantAddressLine1}
            addressState={hearing?.appellantState}
            addressCity={hearing?.appellantCity}
            addressZip={hearing?.appellantZip}
          />
        )}
      {/*
        * Timezone fields
        */}
      {showTimezoneField && (
        <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
          <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })} >
            <Timezone
              required
              value={virtualHearing?.appellantTz}
              onChange={(appellantTz) => update('virtualHearing', { appellantTz })}
              time={hearing.scheduledTimeString}
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
        <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })} >
          <VirtualHearingEmail
            required
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

AppellantSection.propTypes = {
  hearing: PropTypes.object,
  virtualHearing: PropTypes.object,
  errors: PropTypes.object,
  type: PropTypes.string,
  update: PropTypes.func,
  virtual: PropTypes.bool,
  video: PropTypes.bool,
  readOnly: PropTypes.bool,
  appellantTitle: PropTypes.string,
  showOnlyAppellantName: PropTypes.bool,
  showDivider: PropTypes.bool,
  showMissingEmailAlert: PropTypes.bool
};
