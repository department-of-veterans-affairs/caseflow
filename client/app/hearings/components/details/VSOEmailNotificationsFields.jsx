import React from 'react';
import classNames from 'classnames';
import PropTypes from 'prop-types';
import { marginTop, input8px } from '../details/style';
import { HearingEmail } from './HearingEmail';
import { Timezone } from '../VirtualHearings/Timezone';
import { HelperText } from '../VirtualHearings/HelperText';
import COPY from '../../../../COPY';
import { getAppellantTitle, readOnlyEmails } from '../../utils';
export const VSOEmailNotificationsFields = ({
  errors,
  hearing,
  readOnly,
  update,
  time,
  roTimezone,
  appellantEmailAddress,
  appellantTz
}) => {
  const disableField = readOnly || readOnlyEmails(hearing);
  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);

  return (
    <React.Fragment>
      <div id="email-section" className="usa-grid">
        <HearingEmail
          required
          disabled={disableField}
          label={`${appellantTitle} Email`}
          emailType="appellantEmailAddress"
          email={appellantEmailAddress}
          error={errors?.appellantEmailAddress}
          update={update}
          helperLabel={COPY.VIRTUAL_HEARING_EMAIL_HELPER_TEXT_VSO}
        />
        <HearingEmail
          required
          disabled={disableField}
          label={`Confirm ${appellantTitle} Email`}
          emailType="appellantEmailAddress"
          email={null}
          error={errors?.appellantEmailAddress}
          update={update}
          showHelper={false}
        />
        <div
          value={appellantTz}
          className={classNames('usa-grid', { [marginTop(30)]: true })}
          {...input8px}
        >
          <Timezone
            required
            errorMessage={errors?.appellantTz}
            value={appellantTz}
            onChange={() => update('hearing', { appellantTz })}
            readOnly={disableField}
            time={time}
            roTimezone={roTimezone}
            name="appellantTz"
            label={`${getAppellantTitle(
              hearing?.appellantIsNotVeteran
            )} Timezone`}
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
        </div>
      </div>
    </React.Fragment>
  );
};

VSOEmailNotificationsFields.propTypes = {
  requestType: PropTypes.string.isRequired,
  time: PropTypes.string.isRequired,
  roTimezone: PropTypes.string.isRequired,
  appellantTitle: PropTypes.string.isRequired,
  readOnly: PropTypes.bool,
  update: PropTypes.func,
  hearing: PropTypes.object,
  errors: PropTypes.object,
  initialRepresentativeTz: PropTypes.string,
  header: PropTypes.string,
  appellantEmailAddress: PropTypes.string.isRequired,
  appellantTz: PropTypes.string.isRequired
};
