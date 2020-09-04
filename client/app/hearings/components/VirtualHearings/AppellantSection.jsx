import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import COPY from '../../../../COPY';
import { AddressLine } from '../details/Address';
import { VirtualHearingSection } from './Section';
import { HelperText } from './HelperText';
import { VirtualHearingEmail } from './Emails';
import { Timezone } from './Timezone';
import { marginTop, noMaxWidth } from '../details/style';

export const AppellantSection = ({
  hearing,
  virtualHearing,
  errors,
  type,
  virtual,
  video,
  readOnly,
  update,
  appellantTitle
}) => (
  <VirtualHearingSection label={appellantTitle}>
    <AddressLine
      name={hearing?.appellantFullName ?
         hearing?.appellantFullName :
          `${hearing?.veteranFirstName} ${hearing?.veteranLastName}`}
      addressLine1={hearing?.appellantAddressLine1}
      addressState={hearing?.appellantState}
      addressCity={hearing?.appellantCity}
      addressZip={hearing?.appellantZip}
    />
    {virtual && !video && (
      <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
        <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })} >
          <Timezone
            required
            value={virtualHearing?.appellantTz}
            onChange={(appellantTz) => update('virtualHearing', { appellantTz })}
            time={hearing.scheduledTimeString}
            name={`${appellantTitle} Timezone`}
            errorMessage={errors?.appellantTz}
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
        </div>
      </div>
    )}
    <div id="email-section" className={classNames('usa-grid', { [marginTop(30)]: true })}>
      <div className={classNames('usa-width-one-half', { [noMaxWidth]: true })} >
        <VirtualHearingEmail
          required
          readOnly={readOnly}
          label={`${appellantTitle} Email`}
          emailType="appellantEmail"
          email={virtualHearing?.appellantEmail}
          error={errors?.appellantEmail}
          type={type}
          update={update}
        />
      </div>
    </div>
  </VirtualHearingSection>
);

AppellantSection.propTypes = {
  hearing: PropTypes.object,
  virtualHearing: PropTypes.object,
  errors: PropTypes.object,
  type: PropTypes.string,
  update: PropTypes.func,
  virtual: PropTypes.bool,
  video: PropTypes.bool,
  readOnly: PropTypes.bool,
  appellantTitle: PropTypes.string
};
