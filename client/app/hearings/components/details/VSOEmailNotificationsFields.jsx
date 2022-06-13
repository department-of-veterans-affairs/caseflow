import React, { useContext } from 'react';
import classNames from 'classnames';
import PropTypes from 'prop-types';
import { marginTop, input8px } from '../details/style';
import { VSOHearingEmail } from './VSOHearingEmail';
import { Timezone } from '../VirtualHearings/Timezone';
import { HelperText } from '../VirtualHearings/HelperText';
import COPY from '../../../../COPY';
import { getAppellantTitle, readOnlyEmails } from '../../utils';
import HearingTypeConversionContext from '../../contexts/HearingTypeConversionContext';

export const VSOEmailNotificationsFields = ({
  errors,
  hearing,
  readOnly,
  time,
  roTimezone
}) => {
  const { setIsAppellantTZEmpty, updatedAppeal, dispatchAppeal } = useContext(HearingTypeConversionContext);

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
          email={updatedAppeal.appellantEmailAddress}
        />
        <VSOHearingEmail
          required
          disabled={disableField}
          label={`Confirm ${appellantTitle} Email`}
          emailType="appellantEmailAddress"
          error={errors?.appellantEmailAddress}
          showHelper={false}
          confirmEmail
        />
        <div
          value={updatedAppeal.appellantTz}
          className={classNames('usa-grid', { [marginTop(30)]: true })}
          {...input8px}
        >
          <Timezone
            required
            value={updatedAppeal.appellantTz}
            onChange={(appellantTz) => {
              dispatchAppeal({ type: 'SET_APPELLANT_TZ', payload: appellantTz });
              setIsAppellantTZEmpty(!appellantTz);
            }}
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
  requestType: PropTypes.string,
  time: PropTypes.string,
  roTimezone: PropTypes.string,
  appellantTitle: PropTypes.string,
  readOnly: PropTypes.bool,
  update: PropTypes.func,
  hearing: PropTypes.object,
  errors: PropTypes.object,
  initialRepresentativeTz: PropTypes.string,
  header: PropTypes.string
};
