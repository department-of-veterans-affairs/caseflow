import React, { useEffect } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { sprintf } from 'sprintf-js';

import * as DateUtil from '../../util/DateUtil';
import { JudgeDropdown } from '../../components/DataDropdowns/index';
import { spacing, marginTop, noMaxWidth } from './details/style';
import COPY from '../../../COPY';
import { AddressLine } from './details/Address';
import { VirtualHearingSection } from './VirtualHearings/Section';
import { ReadOnly } from './details/ReadOnly';
import { HelperText } from './VirtualHearings/HelperText';
import { VirtualHearingEmail } from './VirtualHearings/Emails';
import { HearingTime } from './modalForms/HearingTime';
import { Timezone } from './VirtualHearings/Timezone';
import { getAppellantTitleForHearing } from '../utils';
import { HEARING_CONVERSION_TYPES } from '../constants';
import { HearingLocationDropdown } from './dailyDocket/DailyDocketRowInputs';

export const HearingConversion = ({
  hearing: { virtualHearing, ...hearing },
  title,
  type,
  scheduledFor,
  errors,
  update,
}) => {
  const appellantTitle = getAppellantTitleForHearing(hearing);
  const virtual = type === 'change_to_virtual';
  const video = hearing.readableRequestType === 'Video';
  const convertLabel = video ? COPY.VIDEO_CHANGE_FROM_VIRTUAL : COPY.CENTRAL_OFFICE_CHANGE_FROM_VIRTUAL;
  const helperLabel = virtual ? COPY.CENTRAL_OFFICE_CHANGE_TO_VIRTUAL : convertLabel;

  // Pre-fill appellant/veteran email address and representative email on mount.
  useEffect(() => {
    // Focus the top of the page
    window.scrollTo(0, 0);

    // Determine which email to use
    const appellantEmail = hearing.appellantIsNotVeteran ? hearing.appellantEmailAddress : hearing.veteranEmailAddress;

    // Try to use the existing timezones if present
    const { appellantTz, representativeTz } = (virtualHearing || {});

    // Set the emails and timezone to defaults if not already set
    if (virtual) {
      update(
        'virtualHearing', {
          [!representativeTz && 'representativeTz']: representativeTz || hearing?.representativeTz,
          [!appellantTz && 'appellantTz']: appellantTz || hearing?.appellantTz,
          [!virtualHearing?.appellantEmail && 'appellantEmail']: appellantEmail,
          [!virtualHearing?.representativeEmail && 'representativeEmail']: hearing.representativeEmailAddress,
        });
    }
  }, []);

  return (
    <AppSegment filledBackground>
      <h1 className="cf-margin-bottom-0">{title}</h1>
      <span>{sprintf(helperLabel, getAppellantTitleForHearing(hearing))}</span>
      <ReadOnly label="Hearing Date" text={DateUtil.formatDateStr(scheduledFor)} />
      <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
        <div className="usa-width-one-half">
          <HearingTime
            vertical
            label="Hearing Time"
            disableRadioOptions={virtual && !video}
            enableZone
            localZone={hearing.regionalOfficeTimezone}
            onChange={(scheduledTimeString) => update('hearing', { scheduledTimeString })}
            value={hearing.scheduledTimeString}
          />
          {!video && <HelperText label={COPY.VIRTUAL_HEARING_TIME_HELPER_TEXT} />}
        </div>
      </div>
      {video && !virtual && (
        <div className={classNames('usa-grid', { [marginTop(30)]: true, [spacing('5px 0', 'pre')]: true })}>
          <div className="usa-width-one-half">
            <ReadOnly label="Regional Office" text={hearing.regionalOfficeName} />
            <HearingLocationDropdown
              regionalOffice={hearing.regionalOfficeKey}
              hearing={hearing}
              update={(values) => update('hearing', values)}
            />
          </div>
        </div>
      )}
      <VirtualHearingSection label={appellantTitle}>
        <AddressLine
          name={`${hearing?.veteranFirstName} ${hearing?.veteranLastName}`}
          addressLine1={hearing?.appellantAddressLine1}
          addressState={hearing?.appellantState}
          addressCity={hearing?.appellantCity}
          addressZip={hearing?.appellantZip}
        />
        {virtual && !video && (
          <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
            <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })} >
              <Timezone
                required
                value={virtualHearing?.appellantTz}
                onChange={(appellantTz) => update('virtualHearing', { appellantTz })}
                time={hearing.scheduledTimeString}
                name={`${appellantTitle} Timezone`}
              />
              <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
            </div>
          </div>
        )}
        <div id="email-section" className={classNames('usa-grid', { [marginTop(30)]: true })}>
          <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })} >
            <VirtualHearingEmail
              required
              readOnly={!virtual}
              label={`${appellantTitle} Email`}
              emailType="appellantEmail"
              email={virtualHearing?.appellantEmail}
              error={errors?.appellantEmail}
              type={type}
              update={update}
            />
          </div>
        </div>
      </VirtualHearingSection>
      <VirtualHearingSection label="Power of Attorney">
        {hearing.representative ? (
          <AddressLine
            label={hearing?.representativeType}
            name={hearing?.representativeName || hearing?.representative}
            addressLine1={hearing?.representativeAddress?.addressLine1}
            addressState={hearing?.representativeAddress?.state}
            addressCity={hearing?.representativeAddress?.city}
            addressZip={hearing?.representativeAddress?.zip}
          />
        ) : (
          <ReadOnly
            text={`The ${getAppellantTitleForHearing(hearing)} does not have a representative recorded in VBMS`}
          />
        )}
        {virtual && !video && (
          <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
            <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })} >
              <Timezone
                errorMessage={errors?.representativeTz}
                required={virtualHearing?.representativeEmail}
                value={virtualHearing?.representativeTz}
                onChange={(representativeTz) => update('virtualHearing', { representativeTz })}
                time={hearing.scheduledTimeString}
                name="POA/Representative Timezone"
                readOnly={!virtualHearing?.representativeEmail}
              />
              <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
            </div>
          </div>
        )}
        <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
          <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })} >
            <VirtualHearingEmail
              readOnly={!virtual}
              emailType="representativeEmail"
              label="POA/Representative Email"
              email={virtual ? virtualHearing?.representativeEmail : virtualHearing?.representativeEmail || 'None'}
              error={errors?.representativeEmail}
              type={type}
              update={update}
            />
          </div>
        </div>
      </VirtualHearingSection>
      <VirtualHearingSection hide={!virtual} label="Veterans Law Judge (VLJ)">
        <div className="usa-grid">
          <div className="usa-width-one-half">
            <JudgeDropdown
              name="judgeDropdown"
              value={hearing?.judgeId}
              onChange={(judgeId) => update('hearing', { judgeId })}
            />
          </div>
        </div>
        <ReadOnly label="VLJ Email" text={hearing.judge?.email || 'N/A'} />
      </VirtualHearingSection>
    </AppSegment>
  );
};

HearingConversion.propTypes = {
  title: PropTypes.string.isRequired,
  type: PropTypes.oneOf(HEARING_CONVERSION_TYPES.slice(0, 2)).isRequired,
  scheduledFor: PropTypes.string.isRequired,
  errors: PropTypes.object,
  update: PropTypes.func,
  hearing: PropTypes.object.isRequired,
};
