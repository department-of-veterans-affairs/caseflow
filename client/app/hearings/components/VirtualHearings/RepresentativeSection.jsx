import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import COPY from '../../../../COPY';
import { AddressLine } from '../details/Address';
import { VirtualHearingSection } from './Section';
import { ReadOnly } from '../details/ReadOnly';
import { HelperText } from './HelperText';
import { VirtualHearingEmail } from './Emails';
import { Timezone } from './Timezone';
import { marginTop } from '../details/style';

export const RepresentativeSection = ({
  hearing,
  virtualHearing,
  errors,
  type,
  readOnly,
  fullWidth,
  update,
  appellantTitle,
  showTimezoneField,
  schedulingToVirtual,
  userCanCollectVideoCentralEmails
}) => (
  <VirtualHearingSection label="Power of Attorney">
    {hearing?.representative ? (
      <React.Fragment>
        <AddressLine
          label={hearing?.representativeType}
          name={hearing?.representativeName || hearing?.representative}
          addressLine1={hearing?.representativeAddress?.addressLine1}
          addressState={hearing?.representativeAddress?.state}
          addressCity={hearing?.representativeAddress?.city}
          addressZip={hearing?.representativeAddress?.zip}
        />
      </React.Fragment>
    ) : (
      <ReadOnly text={`The ${appellantTitle} does not have a representative recorded in VBMS`} />
    )}
    {showTimezoneField && (schedulingToVirtual || userCanCollectVideoCentralEmails) && (
      <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
        <div className={classNames(fullWidth ? 'usa-width-one-whole' : 'usa-width-one-half')}>
          <Timezone
            optional
            errorMessage={errors?.representativeTz}
            required={Boolean(virtualHearing?.representativeEmail)}
            value={virtualHearing?.representativeTz}
            onChange={(representativeTz) =>
              update('virtualHearing', { representativeTz })
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
        <VirtualHearingEmail
          optional
          readOnly={readOnly}
          emailType="representativeEmail"
          label="POA/Representative Email"
          email={virtualHearing?.representativeEmail}
          error={errors?.representativeEmail}
          type={type}
          update={update}
        />
      </div>
    </div>
  </VirtualHearingSection>
);

RepresentativeSection.defaultProps = {
  schedulingToVirtual: true
};

RepresentativeSection.propTypes = {
  hearing: PropTypes.object,
  virtualHearing: PropTypes.object,
  errors: PropTypes.object,
  type: PropTypes.string,
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  fullWidth: PropTypes.bool,
  appellantTitle: PropTypes.string,
  showTimezoneField: PropTypes.bool,
  userCanCollectVideoCentralEmails: PropTypes.bool,
  schedulingToVirtual: PropTypes.bool
};
