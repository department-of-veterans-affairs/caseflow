import React, { useState, useContext, createContext } from 'react';
import classNames from 'classnames';
import PropTypes from 'prop-types';

import { marginTop, input8px } from '../details/style';
import { VSOHearingEmail } from './VSOHearingEmail';
import { Timezone } from '../VirtualHearings/Timezone';
import { HelperText } from '../VirtualHearings/HelperText';
import COPY from '../../../../COPY';
import { getAppellantTitle, readOnlyEmails} from '../../utils';
import { AppellantTZContext, AppellantTZErrorContext } from '../HearingTypeConversion';

export const OriginalEmailContext = createContext([{}, () => {}]);

export const VSOEmailNotificationsFields = ({
  errors,
  hearing,
  readOnly,
  update,
  time,
  roTimezone,
}) => {

  const [isAppellantTZEmpty, setIsAppellantTZEmpty] = useContext(AppellantTZContext);
  const [appellantTZErrorMessage] = useContext(AppellantTZErrorContext);

  const [originalEmail, setOriginalEmail] = useState('');

  const disableField = readOnly || readOnlyEmails(hearing);
  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);

  const timezoneCheck = () => {
    setIsAppellantTZEmpty(false);
  };

  return (
    <OriginalEmailContext.Provider value={[originalEmail, setOriginalEmail]}>
      <React.Fragment>
        <div id="email-section" className="usa-grid">
          <VSOHearingEmail
            required
            disabled={disableField}
            label={`${appellantTitle} Email`}
            emailType="appellantEmailAddress"
            error={errors?.appellantEmailAddress}
            helperLabel={COPY.VIRTUAL_HEARING_EMAIL_HELPER_TEXT_VSO}
            confirmEmail={false}
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
            className={classNames('usa-grid', { [marginTop(30)]: true })}
            {...input8px}
          >
            <Timezone
              required
              errorMessage={isAppellantTZEmpty ? appellantTZErrorMessage : null}
              onChange={(appellantTz) => {
                timezoneCheck(appellantTz);
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
    </OriginalEmailContext.Provider>
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
};
