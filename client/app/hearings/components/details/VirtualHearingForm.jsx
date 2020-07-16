import PropTypes from 'prop-types';
import React, { useContext, useEffect } from 'react';
import classNames from 'classnames';

import { ContentSection } from '../../../components/ContentSection';
import { HearingLinks } from './HearingLinks';
import { HearingsUserContext } from '../../contexts/HearingsUserContext';
import { marginTop } from './style';
import { getAppellantTitleForHearing } from '../../utils';
import { VirtualHearingEmail } from '../VirtualHearings/Emails';
import { Timezone } from '../VirtualHearings/Timezone';
import { HelperText } from '../VirtualHearings/HelperText';
import COPY from '../../../../COPY';

export const VirtualHearingForm = (
  { hearing, virtualHearing, readOnly, update, errors }
) => {
  if (!hearing?.isVirtual && !hearing?.wasVirtual) {
    return null;
  }

  const showEmailFields = (hearing?.isVirtual || hearing?.wasVirtual) && virtualHearing;
  const readOnlyEmails = readOnly || !virtualHearing?.jobCompleted || hearing?.wasVirtual || hearing.scheduledForIsPast;
  const appellantTitle = getAppellantTitleForHearing(hearing);
  const user = useContext(HearingsUserContext);

  // Prefill appellant/veteran email address and representative email on mount.
  useEffect(() => {
    // Try to use the existing timezones if present
    const { appellantTz, representativeTz } = (virtualHearing || {});

    // Set the  timezone if not already set
    update('virtualHearing', {
      [!representativeTz && 'representativeTz']: representativeTz || hearing?.representativeTz,
      [!appellantTz && 'appellantTz']: appellantTz || hearing?.appellantTz,
    });
  }, []);

  return (
    <ContentSection
      header={`${hearing?.wasVirtual ? 'Previous ' : ''}Virtual Hearing Details`}
    >
      <HearingLinks
        user={user}
        hearing={hearing}
        virtualHearing={virtualHearing}
        isVirtual={hearing?.isVirtual}
        wasVirtual={hearing?.wasVirtual}
      />
      <div className="cf-help-divider" />
      {showEmailFields && (
        <React.Fragment>
          <h3>{appellantTitle}</h3>
          <div id="email-section" className="usa-grid">
            <div className="usa-width-one-third">
              <Timezone
                required
                value={virtualHearing?.appellantTz}
                onChange={(appellantTz) => update('virtualHearing', { appellantTz })}
                readOnly={readOnlyEmails}
                time={hearing.scheduledTimeString}
                name={`${appellantTitle} Timezone`}
              />
              <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
            </div>
            <div className="usa-width-one-third">
              <VirtualHearingEmail
                required
                disabled={readOnlyEmails}
                label={`${appellantTitle} Email`}
                emailType="appellantEmail"
                email={virtualHearing?.appellantEmail}
                error={errors?.appellantEmail}
                update={update}
              />
            </div>
          </div>
          <div className="cf-help-divider" />
          <h3>Power of Attorney</h3>
          <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
            <div className="usa-width-one-third">
              <Timezone
                value={virtualHearing?.representativeTz}
                onChange={(representativeTz) => update('virtualHearing', { representativeTz })}
                readOnly={readOnlyEmails || !virtualHearing?.representativeEmail}
                time={hearing.scheduledTimeString}
                name="POA/Representative Timezone"
              />
              <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
            </div>
            <div className="usa-width-one-third">
              <VirtualHearingEmail
                disabled={readOnlyEmails}
                label="POA/Representative Email"
                emailType="representativeEmail"
                email={virtualHearing?.representativeEmail}
                error={errors?.representativeEmail}
                update={update}
              />
            </div>
          </div>
        </React.Fragment>
      )}
    </ContentSection>
  );
};

VirtualHearingForm.propTypes = {
  update: PropTypes.func,
  hearing: PropTypes.shape({
    scheduledTimeString: PropTypes.string,
    appellantIsNotVeteran: PropTypes.bool,
    scheduledForIsPast: PropTypes.bool,
    wasVirtual: PropTypes.bool,
    isVirtual: PropTypes.bool
  }),
  readOnly: PropTypes.bool,
  virtualHearing: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
    jobCompleted: PropTypes.bool
  }),
  errors: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string
  })
};
