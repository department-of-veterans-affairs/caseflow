import React, { useEffect } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import classnames from 'classnames';

import * as DateUtil from '../../util/DateUtil';
import { JudgeDropdown } from '../../components/DataDropdowns/index';
import { fullWidth, marginTop, enablePadding, maxWidthFormInput, leftAlign, helperLabel } from './details/style';
import TextField from '../../components/TextField';

export const LeftAlign = ({ children }) => (
  <div {...leftAlign}>
    {children}
    <div />
  </div>
);

export const AddressLine = ({ name, addressLine1, addressState, addressCity, addressZip }) => (
  <div>
    <span {...fullWidth}>{name}</span>
    <span {...fullWidth}>{addressLine1}</span>
    <span {...fullWidth}>
      {addressCity}, {addressState} {addressZip}
    </span>
  </div>
);

export const HelperText = () => (
  <span {...helperLabel}>Changes to the email are used to send notifications for this hearing only</span>
);

export const DisplayValue = ({ label, children }) => (
  <div {...marginTop(25)}>
    <strong>{label}</strong>
    {children}
  </div>
);

export const VirtualHearingSection = ({ label, children }) => (
  <React.Fragment>
    <div className="cf-help-divider" />
    <h3>{label}</h3>
    {children}
  </React.Fragment>
);

export const HearingConversion = ({ hearing, scheduledFor, errors, readOnlyEmails, update }) => {
  const { virtualHearing } = hearing;

  // Prefill appellant/veteran email address and representative email on mount.
  useEffect(() => {
    // Determine which email to use
    const appellantEmail = hearing.appellantIsNotVeteran ? hearing.appellantEmailAddress : hearing.veteranEmailAddress;

    // Set the emails if not already set
    update('virtualHearing', {
      [!virtualHearing?.appellantEmail && 'appellantEmail']: appellantEmail,
      [!virtualHearing?.representativeEmail && 'representativeEmail']: hearing.representativeEmailAddress
    });
  }, []);

  return (
    <AppSegment filledBackground>
      <h1 className="cf-margin-bottom-0">Convert to Virtual Hearing</h1>
      <span>Email notifications will be sent to the Veteran, POA / Representative, and Veterans Law Judge (VLJ).</span>
      <DisplayValue label="Hearing Time">
        <span {...fullWidth}>{DateUtil.formatDateStr(scheduledFor)}</span>
      </DisplayValue>
      <VirtualHearingSection label="Veteran">
        <DisplayValue label="">
          <AddressLine
            name={`${hearing?.veteranFirstName} ${hearing?.veteranLastName}`}
            addressLine1={hearing?.appellantAddressLine1}
            addressState={hearing?.appellantState}
            addressCity={hearing?.appellantCity}
            addressZip={hearing?.appellantZip}
          />
        </DisplayValue>
        <LeftAlign>
          <TextField
            errorMessage={errors?.appellantEmail}
            name="Veteran Email"
            value={virtualHearing?.appellantEmail}
            required
            strongLabel
            className={[
              classnames('cf-form-textinput', 'cf-inline-field', {
                [enablePadding]: errors?.appellantEmail
              })
            ]}
            readOnly={readOnlyEmails}
            onChange={(appellantEmail) =>
              update('virtualHearing', { appellantEmail })
            }
            inputStyling={maxWidthFormInput}
          />
        </LeftAlign>
        <HelperText />
      </VirtualHearingSection>
      <VirtualHearingSection label="Power of Attorney">
        <DisplayValue label="Attorney">
          <AddressLine
            name={hearing?.representativeName}
            addressLine1={hearing?.appellantAddressLine1}
            addressState={hearing?.appellantState}
            addressCity={hearing?.appellantCity}
            addressZip={hearing?.appellantZip}
          />
        </DisplayValue>
        <LeftAlign>
          <TextField
            errorMessage={errors?.repEmail}
            name="POA/Representative Email"
            value={virtualHearing?.representativeEmail}
            strongLabel
            className={[classnames('cf-form-textinput', 'cf-inline-field')]}
            readOnly={readOnlyEmails}
            onChange={(representativeEmail) =>
              update('virtualHearing', { representativeEmail })
            }
            inputStyling={maxWidthFormInput}
          />
        </LeftAlign>
        <HelperText />
      </VirtualHearingSection>
      <VirtualHearingSection label="Veterans Law Judge (VLJ)">
        <LeftAlign>
          <JudgeDropdown
            name="judgeDropdown"
            value={hearing?.judgeId}
            onChange={(judgeId) => update('virtualHearing', { judgeId })}
          />
        </LeftAlign>
        <DisplayValue label="VLJ Email">
          <span {...fullWidth}>{hearing.judge?.email || 'N/A'}</span>
        </DisplayValue>
      </VirtualHearingSection>
    </AppSegment>
  );
};

HearingConversion.propTypes = {
  scheduledFor: PropTypes.string,
  hearing: PropTypes.object
};
