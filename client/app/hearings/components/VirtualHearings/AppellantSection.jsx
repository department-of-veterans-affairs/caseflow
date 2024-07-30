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

export const AppellantSection = ({
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
      {!formFieldsOnly && (
        <React.Fragment>
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
        </React.Fragment>
      )}
      {/*
        * Timezone fields
        */}
      {showTimezoneField && (
        <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
          <div className={classNames(columnWidthClass)} >
            <Timezone
              required={schedulingToVirtual}
              optional={!schedulingToVirtual}
              value={appellantTimezone || hearing?.appellantTz}
              onChange={(appellantTz) => update('hearing', { appellantTz })}
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
          <HearingEmail
            required={schedulingToVirtual}
            optional={!schedulingToVirtual}
            readOnly={readOnly}
            label={`${appellantTitle} Email (for these notifications only)`}
            emailType={appellantEmailType}
            email={appellantEmailAddress}
            error={errors?.appellantEmailAddress}
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
