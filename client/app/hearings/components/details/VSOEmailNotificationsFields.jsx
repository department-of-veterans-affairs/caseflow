import React from 'react';
import classNames from 'classnames';
import PropTypes from 'prop-types';
import { marginTop, input8px } from '../details/style';
import { VSOHearingEmail } from './VSOHearingEmail';
import { Timezone } from '../VirtualHearings/Timezone';
import { HelperText } from '../VirtualHearings/HelperText';
import COPY from '../../../../COPY';
import { getAppellantTitle, readOnlyEmails } from '../../utils';

export const VSOEmailNotificationsFields = ({
  errors,
  hearing,
  readOnly,
  roTimezone,
  setIsValidEmail,
  actionType,
  update,
  hearingDayDate
}) => {
  const disableField = readOnly || readOnlyEmails(hearing);
  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);

  return (
    <React.Fragment>
      <div id="email-section" className="usa-grid">
        <VSOHearingEmail
          required
          disabled={disableField}
          label={`${appellantTitle} Email`}
          emailType="appellantEmailAddress"
          error={errors?.appellantEmailAddress}
          helperLabel={COPY.VIRTUAL_HEARING_EMAIL_HELPER_TEXT_VSO}
          email={hearing?.appellantEmailAddress}
          update={update}
          hearing={hearing}
          setIsValidEmail={setIsValidEmail}
          actionType={actionType}
        />
        <VSOHearingEmail
          required
          disabled={disableField}
          label={`Confirm ${appellantTitle} Email`}
          emailType="appellantEmailAddress"
          error={errors?.appellantEmailAddress}
          showHelper={false}
          update={update}
          hearing={hearing}
          actionType={actionType}
          confirmEmail
        />
        <div
          value={hearing.appellantTz}
          className={classNames('usa-grid', { [marginTop(30)]: true })}
          {...input8px}
        >
          <Timezone
            required
            value={hearing?.appellantTz}
            onChange={(appellantTz) =>
              update(actionType, { appellantTz })
            }
            readOnly={disableField}
            time={hearing?.scheduledTimeString}
            roTimezone={roTimezone}
            name="appellantTz"
            label={`${getAppellantTitle(
              hearing?.appellantIsNotVeteran
            )} Timezone`}
            hearingDayDate={hearingDayDate}
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
        </div>
      </div>
    </React.Fragment>
  );
};

VSOEmailNotificationsFields.propTypes = {
  requestType: PropTypes.string,
  time: PropTypes.string,
  roTimezone: PropTypes.string,
  appellantTitle: PropTypes.string,
  readOnly: PropTypes.bool,
  update: PropTypes.func,
  hearing: PropTypes.object,
  errors: PropTypes.object,
  initialRepresentativeTz: PropTypes.string,
  header: PropTypes.string,
  setEmailsMismatch: PropTypes.func,
  setIsValidEmail: PropTypes.func,
  setConfirmIsEmpty: PropTypes.func,
  confirmIsEmpty: PropTypes.bool,
  actionType: PropTypes.string,
  hearingDayDate: PropTypes.string
};
