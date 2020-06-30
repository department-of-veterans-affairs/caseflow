import React, { useEffect } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import * as DateUtil from '../../util/DateUtil';
import { JudgeDropdown } from '../../components/DataDropdowns/index';
import { fullWidth, marginTop, noMaxWidth } from './details/style';
import COPY from '../../../COPY';
import {
  AddressLine,
  VirtualHearingSection,
  DisplayValue,
  LeftAlign,
  VerticalAlign,
} from './conversion';
import { HelperText } from './VirtualHearings/HelperText';
import { VirtualHearingEmail } from './VirtualHearings/Emails';
import { HearingTime } from './modalForms/HearingTime';
import { Timezone } from './VirtualHearings/Timezone';
import { getAppellantTitleForHearing } from '../utils';

export const HearingConversion = ({
  title,
  hearing,
  type,
  scheduledFor,
  errors,
  update,
}) => {
  const { virtualHearing } = hearing;
  const appellantTitle = getAppellantTitleForHearing(hearing);
  const virtual = type === 'change_to_virtual';
  const helperLabel = virtual ?
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
      <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
        <div className="usa-width-one-half">
          <VerticalAlign>
            <HearingTime
              label="Hearing Time"
              disableRadioOptions={virtual}
              enableZone
              onChange={(scheduledTimeString) =>
                update('hearing', { scheduledTimeString })
              }
              value={hearing.scheduledTimeString}
            />
          </VerticalAlign>
        </div>
      </div>
      <VirtualHearingSection label={appellantTitle}>
        <DisplayValue label="">
          <AddressLine
            name={`${hearing?.veteranFirstName} ${hearing?.veteranLastName}`}
            addressLine1={hearing?.appellantAddressLine1}
            addressState={hearing?.appellantState}
            addressCity={hearing?.appellantCity}
            addressZip={hearing?.appellantZip}
          />
        </DisplayValue>
        {virtual && (
          <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
            <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })}>
              <Timezone
                required
                time={hearing.scheduledTimeString}
                name={`${appellantTitle} Timezone`}
              />
              <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
            </div>
          </div>
        )}
        <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
          <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })}>
            <VirtualHearingEmail
              required
              readOnly={!virtual}
              label="Veteran Email"
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
        <DisplayValue label="Attorney">
          <AddressLine
            name={hearing?.representativeName}
            addressLine1={hearing?.appellantAddressLine1}
            addressState={hearing?.appellantState}
            addressCity={hearing?.appellantCity}
            addressZip={hearing?.appellantZip}
          />
        </DisplayValue>
        {virtual && (
          <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
            <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })}>
              <Timezone
                time={hearing.scheduledTimeString}
                name="POA/Representative Timezone"
              />
              <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
            </div>
          </div>
        )}
        <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
          <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })}>
            <VirtualHearingEmail
              readOnly={!virtual}
              emailType="representativeEmail"
              label="POA/Representative Email"
              email={virtualHearing?.representativeEmail}
              error={errors?.representativeEmail}
              type={type}
              update={update}
            />
          </div>
        </div>
      </VirtualHearingSection>
      <VirtualHearingSection hide={!virtual} label="Veterans Law Judge (VLJ)">
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
  title: PropTypes.string,
  type: PropTypes.string,
  scheduledFor: PropTypes.string,
  errors: PropTypes.object,
  update: PropTypes.func,
  hearing: PropTypes.object,
};
