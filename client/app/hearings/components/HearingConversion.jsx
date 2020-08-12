import React, { useEffect } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import * as DateUtil from '../../util/DateUtil';
import { JudgeDropdown } from '../../components/DataDropdowns/index';
import { marginTop } from './details/style';
import COPY from '../../../COPY';
import { VirtualHearingSection } from './VirtualHearings/Section';
import { ReadOnly } from './details/ReadOnly';
import { HelperText } from './VirtualHearings/HelperText';
import { HearingTime } from './modalForms/HearingTime';
import { getAppellantTitleForHearing } from '../utils';
import { HEARING_CONVERSION_TYPES } from '../constants';
import { RepresentativeSection } from './VirtualHearings/RepresentativeSection';
import { AppellantSection } from './VirtualHearings/AppellantSection';

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
  const helperLabel = virtual ? COPY.CENTRAL_OFFICE_CHANGE_TO_VIRTUAL : COPY.CENTRAL_OFFICE_CHANGE_FROM_VIRTUAL;

  // Set the section props
  const sectionProps = { hearing, virtualHearing, virtual, type, errors, update, appellantTitle, readOnly: !virtual };

  // Prefill appellant/veteran email address and representative email on mount.
  useEffect(() => {
    // Focus the top of the page
    window.scrollTo(0, 0);

    // Determine which email to use
    const appellantEmail = hearing.appellantIsNotVeteran ? hearing.appellantEmailAddress : hearing.veteranEmailAddress;

    // Try to use the existing timezones if present
    const { appellantTz, representativeTz } = (virtualHearing || {});

    // Set the emails and timezone if not already set
    update('virtualHearing', {
      [!representativeTz && 'representativeTz']: representativeTz || hearing?.representativeTz,
      [!appellantTz && 'appellantTz']: appellantTz || hearing?.appellantTz,
      [!virtualHearing?.appellantEmail && 'appellantEmail']: appellantEmail,
      [!virtualHearing?.representativeEmail && 'representativeEmail']: hearing.representativeEmailAddress,
    });
  }, []);

  return (
    <AppSegment filledBackground>
      <h1 className="cf-margin-bottom-0">{title}</h1>
      <span>{helperLabel}</span>
      <ReadOnly label="Hearing Date" text={DateUtil.formatDateStr(scheduledFor)} />
      <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
        <div className="usa-width-one-half">
          <HearingTime
            vertical
            label="Hearing Time"
            disableRadioOptions={virtual}
            enableZone
            onChange={(scheduledTimeString) => update('hearing', { scheduledTimeString })}
            value={hearing.scheduledTimeString}
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIME_HELPER_TEXT} />
        </div>
      </div>
      <AppellantSection {...sectionProps} />
      <RepresentativeSection {...sectionProps} />
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
