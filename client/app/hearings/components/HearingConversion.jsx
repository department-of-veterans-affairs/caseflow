import React, { useEffect, useState } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { sprintf } from 'sprintf-js';
import moment from 'moment-timezone';

import * as DateUtil from '../../util/DateUtil';
import { JudgeDropdown } from '../../components/DataDropdowns/index';
import { marginTop } from './details/style';
import COPY from '../../../COPY';
import { VirtualHearingSection } from './VirtualHearings/Section';
import { ReadOnly } from './details/ReadOnly';
import { HelperText } from './VirtualHearings/HelperText';
import { HearingTime } from './modalForms/HearingTime';
import { getAppellantTitle } from '../utils';
import { HEARING_CONVERSION_TYPES } from '../constants';
import { RepresentativeSection } from './VirtualHearings/RepresentativeSection';
import { AppellantSection } from './VirtualHearings/AppellantSection';
import { VSORepresentativeSection } from './VirtualHearings/VSORepresentativeSection';
import { VSOAppellantSection } from './VirtualHearings/VSOAppellantSection';
import { Checkbox } from '../../components/Checkbox';
import Link from '../../components/Link';

export const HearingConversion = ({
  hearing: { virtualHearing, ...hearing },
  title,
  type,
  scheduledFor,
  errors,
  update,
  userVsoEmployee,
  setIsValidEmail,
  updateCheckboxes
}) => {
  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);
  const virtual = type === 'change_to_virtual';
  const video = hearing.readableRequestType === 'Video';
  const convertLabel = video ? COPY.VIDEO_CHANGE_FROM_VIRTUAL : COPY.CENTRAL_OFFICE_CHANGE_FROM_VIRTUAL;
  const hearingDayDate = moment(hearing.scheduledFor).format('YYYY-MM-DD');

  let helperLabel = '';

  if ((virtual && userVsoEmployee) === true) {
    helperLabel = COPY.CONVERT_HEARING_TYPE_SUBTITLE_3;
  } else if ((virtual && !userVsoEmployee) === true) {
    helperLabel = COPY.CENTRAL_OFFICE_CHANGE_TO_VIRTUAL;
  } else {
    helperLabel = convertLabel;
  }

  // set values for checkboxes
  const [checkboxPermission, setCheckboxPermission] = useState(false);
  const [checkboxAccess, setCheckboxAccess] = useState(false);

  // Set the section props
  const sectionProps = {
    hearing,
    virtualHearing,
    type,
    errors,
    update,
    appellantTitle,
    appellantEmailAddress: hearing?.appellantEmailAddress,
    representativeEmailAddress: hearing?.representativeEmailAddress,
    appellantEmailType: 'appellantEmailAddress',
    representativeEmailType: 'representativeEmailAddress',
    showTimezoneField: true,
    schedulingToVirtual: virtual,
    userVsoEmployee,
    actionType: 'hearing',
    setIsValidEmail,
    hearingDayDate
  };

  const prefillFields = () => {
    // Try to use the existing timezones if present
    update(
      'hearing', {
        ...hearing,
        representativeTz: userVsoEmployee ?
        hearing?.currentUserTimezone :
        hearing?.representativeTz || hearing?.appellantTz,
        representativeEmailAddress: userVsoEmployee ?
        hearing?.currentUserEmail :
        hearing?.representativeEmailAddress
      });
  };

  useEffect(() => {
    updateCheckboxes(checkboxAccess && checkboxPermission);
  }, [checkboxAccess, checkboxPermission]);

  // Pre-fill appellant/veteran email address and representative email on mount.
  useEffect(() => {
    // Focus the top of the page
    window.scrollTo(0, 0);

    // Set the representative emails and timezone to defaults if not already set
    if (virtual) {
      prefillFields();
    }
  }, []);

  return (
    <AppSegment filledBackground>
      <h1 className="cf-margin-bottom-0">{title}</h1>
      <span>{sprintf(helperLabel, appellantTitle)}</span>
      {!userVsoEmployee && <div>
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
              hearingDayDate={hearingDayDate}
            />
            {!video && <HelperText label={COPY.VIRTUAL_HEARING_TIME_HELPER_TEXT} />}
          </div>
        </div>
      </div>}

      {userVsoEmployee ?
        (<div>
          <VSOAppellantSection {...sectionProps} />
          <VSORepresentativeSection {...sectionProps} readOnly />
        </div>) :
        (<div>
          <AppellantSection {...sectionProps} />
          <RepresentativeSection {...sectionProps} />
        </div>)
      }

      {userVsoEmployee &&
        <div label="vsoCheckboxes">
          <Checkbox
            label={COPY.CONVERT_HEARING_TYPE_CHECKBOX_AFFIRM_PERMISSION}
            name="affirmPermission"
            id="affirmPermission"
            value={checkboxPermission}
            onChange={(checked) => setCheckboxPermission(checked)}
          />
          <div />
          <Checkbox
            label={
              <div>
                <span>{COPY.CONVERT_HEARING_TYPE_CHECKBOX_AFFIRM_ACCESS}</span>&nbsp;
                <Link href="https://www.bva.va.gov/docs/VirtualHearing_FactSheet.pdf" target="_blank">
                  Learn more
                </Link>
              </div>
            }
            name="affirmAccess"
            id="affirmAccess"
            value={checkboxAccess}
            onChange={(checked) => setCheckboxAccess(checked)}
          />
        </div>
      }
      <VirtualHearingSection hide={!virtual || userVsoEmployee} label="Veterans Law Judge (VLJ)">
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
  userVsoEmployee: PropTypes.bool,
  setIsValidEmail: PropTypes.func,
  updateCheckboxes: PropTypes.func
};
