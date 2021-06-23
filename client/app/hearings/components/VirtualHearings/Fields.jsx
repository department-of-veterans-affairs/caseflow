import React from 'react';
import classNames from 'classnames';
import PropTypes from 'prop-types';

import { marginTop, input8px } from '../details/style';
import { VirtualHearingEmail } from './Emails';
import { Timezone } from './Timezone';
import { HelperText } from './HelperText';
import COPY from '../../../../COPY';

export const VirtualHearingFields = ({
  errors,
  appellantTitle,
  initialRepresentativeTz,
  virtualHearing,
  readOnly,
  update,
  time,
  roTimezone
}) => {
  return (
    <React.Fragment>
      <h3>{appellantTitle}</h3>
      <div id="email-section" className="usa-grid">
        <div className="usa-width-one-third" {...input8px}>
          <Timezone
            required
            errorMessage={errors?.appellantTz}
            value={virtualHearing?.appellantTz}
            onChange={(appellantTz) => update('virtualHearing', { appellantTz })}
            readOnly={readOnly}
            time={time}
            roTimezone={roTimezone}
            name="appellantTz"
            label={`${appellantTitle} Timezone`}
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
        </div>
        <div className="usa-width-one-third">
          <VirtualHearingEmail
            required
            disabled={readOnly}
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
        <div className="usa-width-one-third" {...input8px}>
          <Timezone
            errorMessage={errors?.representativeTz}
            required={Boolean(virtualHearing?.representativeEmail)}
            value={virtualHearing?.representativeTz}
            onChange={(representativeTz) => update('virtualHearing', { representativeTz })}
            readOnly={readOnly || !virtualHearing?.representativeEmail}
            time={time}
            roTimezone={roTimezone}
            name="representativeTz"
            label="POA/Representative Timezone"
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
        </div>
        <div className="usa-width-one-third">
          <VirtualHearingEmail
            disabled={readOnly}
            label="POA/Representative Email"
            emailType="representativeEmail"
            email={virtualHearing?.representativeEmail}
            error={errors?.representativeEmail}
            update={(key, value) => {
              // Switch the representative timezone back to the initial value if the
              // representative email is changed to null. This should prevent `deepDiff``
              // from trying to send any changes to the representative timezone if the
              // representative email is being removed.
              if (!value.representativeEmail) {
                value.representativeTz = initialRepresentativeTz;
              }

              update(key, value);
            }}
          />
        </div>
      </div>
    </React.Fragment>
  );
};

VirtualHearingFields.propTypes = {
  requestType: PropTypes.string.isRequired,
  time: PropTypes.string.isRequired,
  roTimezone: PropTypes.string.isRequired,
  appellantTitle: PropTypes.string.isRequired,
  readOnly: PropTypes.bool,
  update: PropTypes.func,
  virtualHearing: PropTypes.object,
  errors: PropTypes.object,
  initialRepresentativeTz: PropTypes.string,
};
