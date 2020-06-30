import React, { useEffect } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';

import * as DateUtil from '../../util/DateUtil';
import { JudgeDropdown } from '../../components/DataDropdowns/index';
import { fullWidth } from './details/style';
import COPY from '../../../COPY';
import {
  AddressLine,
  VirtualHearingEmail,
  VirtualHearingSection,
  DisplayValue,
  LeftAlign,
  VerticalAlign,
} from './conversion';
import { HearingTime } from './modalForms/HearingTime';

export const HearingConversion = ({
  title,
  hearing,
  type,
  scheduledFor,
  errors,
  update,
}) => {
  const { virtualHearing } = hearing;
  const virtual = type === 'change_to_virtual';
  const helperLabel =
    type === 'change_to_virtual' ?
      COPY.CENTRAL_OFFICE_CHANGE_TO_VIRTUAL :
      COPY.CENTRAL_OFFICE_CHANGE_FROM_VIRTUAL;

  // Prefill appellant/veteran email address and representative email on mount.
  useEffect(() => {
    // Determine which email to use
    const appellantEmail = hearing.appellantIsNotVeteran ?
      hearing.appellantEmailAddress :
      hearing.veteranEmailAddress;

    // Set the emails if not already set
    update('virtualHearing', {
      [!virtualHearing?.appellantEmail && 'appellantEmail']: appellantEmail,
      [!virtualHearing?.representativeEmail &&
      'representativeEmail']: hearing.representativeEmailAddress,
    });
  }, []);

  return (
    <AppSegment filledBackground>
      <h1 className="cf-margin-bottom-0">{title}</h1>
      <span>{helperLabel}</span>
      <DisplayValue label="Hearing Date">
        <span {...fullWidth}>{DateUtil.formatDateStr(scheduledFor)}</span>
      </DisplayValue>
      <LeftAlign>
        <VerticalAlign>
          <HearingTime
            label="Hearing Time"
            disableRadioOptions={type === 'change_to_virtual'}
            enableZone
            onChange={(scheduledTimeString) => update('hearing', { scheduledTimeString })}
            value={hearing.scheduledTimeString}
          />
        </VerticalAlign>
      </LeftAlign>
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
        <VirtualHearingEmail
          required
          label="Veteran Email"
          email={virtualHearing?.appellantEmail}
          error={errors?.appellantEmail}
          type={type}
          update={update}
        />
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
        <VirtualHearingEmail
          label="POA/Representative Email"
          email={virtualHearing?.representativeEmail}
          error={errors?.representativeEmail}
          type={type}
          update={update}
        />
      </VirtualHearingSection>
      <VirtualHearingSection
        hide={type === 'change_from_virtual'}
        label="Veterans Law Judge (VLJ)"
      >
        <LeftAlign>
          <JudgeDropdown
            name="judgeDropdown"
            value={hearing?.judgeId}
            onChange={(judgeId) => update('hearing', { judgeId })}
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
  type: PropTypes.string,
  scheduledFor: PropTypes.string,
  errors: PropTypes.object,
  update: PropTypes.func,
  hearing: PropTypes.object,
};
