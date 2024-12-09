import React from 'react';
import classNames from 'classnames';
import PropTypes from 'prop-types';
import moment from 'moment-timezone';

import { marginTop, input8px } from '../details/style';
import { HearingEmail } from './HearingEmail';
import { EmailNotificationHistory } from './EmailNotificationHistory';
import { Timezone } from '../VirtualHearings/Timezone';
import { HelperText } from '../VirtualHearings/HelperText';
import { ContentSection } from '../../../components/ContentSection';
import COPY from '../../../../COPY';
import { getAppellantTitle, readOnlyEmails } from '../../utils';

export const EmailNotificationFields = ({
  errors,
  initialRepresentativeTz,
  hearing,
  readOnly,
  update,
  time,
  roTimezone,
  header
}) => {
  const disableField = readOnly || readOnlyEmails(hearing);
  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);
  const hearingDayDate = moment(hearing.scheduledFor).format('YYYY-MM-DD');

  return (
    <ContentSection header={header}>
      <React.Fragment>
        <div id="email-section" className="usa-grid">
          <div className="usa-width-one-third" {...input8px}>
            <Timezone
              required={hearing?.isVirtual}
              optional={!hearing?.isVirtual}
              errorMessage={errors?.appellantTz}
              value={hearing?.appellantTz}
              onChange={(appellantTz) => update('hearing', { appellantTz })}
              readOnly={disableField}
              time={time}
              roTimezone={roTimezone}
              name="appellantTz"
              label={`${getAppellantTitle(hearing?.appellantIsNotVeteran)} Timezone`}
              hearingDayDate={hearingDayDate}
            />
            <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
          </div>
          <div className="usa-width-one-third">
            <HearingEmail
              required={hearing?.isVirtual}
              optional={!hearing?.isVirtual}
              disabled={disableField}
              label={`${appellantTitle} Email`}
              emailType="appellantEmailAddress"
              email={hearing?.appellantEmailAddress}
              error={errors?.appellantEmailAddress}
              update={update}
            />
          </div>
        </div>
        <div className="cf-help-divider" />
        <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
          <div className="usa-width-one-third" {...input8px}>
            <Timezone
              required={Boolean(hearing?.representativeEmailAddress)}
              optional={!hearing?.representativeEmailAddress}
              errorMessage={errors?.representativeTz}
              value={hearing?.representativeTz}
              onChange={(representativeTz) => update('hearing', { representativeTz })}
              readOnly={disableField || !hearing?.representativeEmailAddress}
              time={time}
              roTimezone={roTimezone}
              name="representativeTz"
              label="POA/Representative Timezone"
              hearingDayDate={hearingDayDate}
            />
            <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
          </div>
          <div className="usa-width-one-third">
            <HearingEmail
              optional
              disabled={disableField}
              label="POA/Representative Email"
              emailType="representativeEmailAddress"
              email={hearing?.representativeEmailAddress}
              error={errors?.representativeEmailAddress}
              update={(key, value) => {
                // Switch the representative timezone back to the initial value if the
                // representative email is changed to null. This should prevent `deepDiff``
                // from trying to send any changes to the representative timezone if the
                // representative email is being removed.
                if (!value.representativeEmailAddress) {
                  value.representativeTz = initialRepresentativeTz;
                }

                update(key, value);
              }}
            />
          </div>
        </div>
        {hearing?.emailEvents?.length > 0 && (
          <EmailNotificationHistory rows={hearing?.emailEvents} />
        )}
      </React.Fragment>
    </ContentSection>
  );
};

EmailNotificationFields.propTypes = {
  requestType: PropTypes.string.isRequired,
  time: PropTypes.string.isRequired,
  roTimezone: PropTypes.string.isRequired,
  appellantTitle: PropTypes.string.isRequired,
  readOnly: PropTypes.bool,
  update: PropTypes.func,
  hearing: PropTypes.object,
  errors: PropTypes.object,
  initialRepresentativeTz: PropTypes.string,
  header: PropTypes.string
};
