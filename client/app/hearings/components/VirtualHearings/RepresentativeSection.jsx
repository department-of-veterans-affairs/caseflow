import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import COPY from '../../../../COPY';
import { AddressLine } from '../details/Address';
import { VirtualHearingSection } from './Section';
import { ReadOnly } from '../details/ReadOnly';
import { HelperText } from './HelperText';
import { HearingEmail } from '../details/HearingEmail';
import { Timezone } from './Timezone';
import { marginTop } from '../details/style';

export const RepresentativeSection = ({
  hearing,
  errors,
  type,
  readOnly,
  fullWidth,
  update,
  appellantTitle,
  showTimezoneField,
  showDivider,
  formFieldsOnly,
  representativeTimezone,
  representativeEmailAddress,
  representativeEmailType
}) => (
  <VirtualHearingSection formFieldsOnly={formFieldsOnly} label="Power of Attorney (POA)" showDivider={showDivider}>
    {hearing?.representative ? (
      <React.Fragment>
        {formFieldsOnly ? (
          <ReadOnly label={hearing?.representativeType} text={hearing?.representativeName || hearing?.representative} />
        ) : (
          <AddressLine
            label={hearing?.representativeType}
            name={hearing?.representativeName || hearing?.representative}
            addressLine1={hearing?.representativeAddress?.addressLine1}
            addressState={hearing?.representativeAddress?.state}
            addressCity={hearing?.representativeAddress?.city}
            addressZip={hearing?.representativeAddress?.zip}
          />
        )}
      </React.Fragment>
    ) : (
      <ReadOnly text={`The ${appellantTitle} does not have a representative recorded in VBMS`} />
    )}
    {showTimezoneField && (
      <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
        <div className={classNames(fullWidth ? 'usa-width-one-whole' : 'usa-width-one-half')}>
          <Timezone
            optional={!representativeEmailAddress}
            errorMessage={errors?.representativeTz}
            required={Boolean(representativeEmailAddress)}
            value={representativeTimezone || hearing?.representativeTz}
            onChange={(representativeTz) =>
              update('hearing', { representativeTz })
            }
            time={hearing.scheduledTimeString}
            roTimezone={hearing?.regionalOfficeTimezone}
            label="POA/Representative Timezone"
            name="representativeTz"
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
        </div>
      </div>
    )}
    <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
      <div className={classNames(fullWidth ? 'usa-width-one-whole' : 'usa-width-one-half')} >
        <HearingEmail
          optional
          readOnly={readOnly}
          emailType={representativeEmailType}
          label="POA/Representative Email (for these notifications only)"
          email={representativeEmailAddress}
          error={errors?.representativeEmailAddress}
          type={type}
          update={update}
        />
      </div>
    </div>
  </VirtualHearingSection>
);

RepresentativeSection.defaultProps = {
  schedulingToVirtual: true,
  formFieldsOnly: false
};

RepresentativeSection.propTypes = {
  hearing: PropTypes.object,
  errors: PropTypes.object,
  type: PropTypes.string,
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  fullWidth: PropTypes.bool,
  appellantTitle: PropTypes.string,
  showTimezoneField: PropTypes.bool,
  userCanCollectVideoCentralEmails: PropTypes.bool,
  schedulingToVirtual: PropTypes.bool,
  showDivider: PropTypes.bool,
  formFieldsOnly: PropTypes.bool,
  representativeTimezone: PropTypes.string,
  representativeEmailAddress: PropTypes.string,
  representativeEmailType: PropTypes.string,
  userVsoEmployee: PropTypes.bool
};
