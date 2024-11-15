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

export const VSORepresentativeSection = ({
  hearing,
  errors,
  fullWidth,
  appellantTitle,
  showDivider,
  formFieldsOnly,
  readOnly,
  update,
  actionType,
  hearingDayDate
}) => {
  return (
    <VirtualHearingSection
      formFieldsOnly={formFieldsOnly}
      label="Power of Attorney (POA)"
      showDivider={showDivider}
    >
      {hearing.representative ? (
        <React.Fragment>
          {formFieldsOnly ? (
            <ReadOnly
              label={hearing.representativeType}
              text={hearing.representativeName || hearing.representative}
            />
          ) : (
            <AddressLine
              label={hearing.representativeType}
              name={hearing.representativeName || hearing.representative}
              addressLine1={hearing.representativeAddress?.addressLine1}
              addressState={hearing.representativeAddress?.state}
              addressCity={hearing.representativeAddress?.city}
              addressZip={hearing.representativeAddress?.zip}
            />
          )}
        </React.Fragment>
      ) : (
        <ReadOnly
          text={`The ${appellantTitle} does not have a representative recorded in VBMS`}
        />
      )}

      <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
        <div
          className={classNames(
            fullWidth ? 'usa-width-one-whole' : 'usa-width-one-half'
          )}
        >
          <HearingEmail
            optional
            readOnly={readOnly}
            emailType="representativeEmailAddress"
            label="POA/Representative Email"
            error={errors?.representativeEmailAddress}
            email={hearing.representativeEmailAddress}
            update={update}
            actionType={actionType}
          />
        </div>
      </div>

      <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
        <div
          className={classNames(
            fullWidth ? 'usa-width-one-whole' : 'usa-width-one-half'
          )}
        >
          <Timezone
            required
            value={hearing.representativeTz}
            onChange={(representativeTz) =>
              update(actionType, { representativeTz })
            }
            time={hearing.scheduledTimeString}
            roTimezone={hearing.regionalOfficeTimezone}
            label="POA/Representative Timezone"
            name="representativeTz"
            hearingDayDate={hearingDayDate}
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
        </div>
      </div>
    </VirtualHearingSection>
  );
};

VSORepresentativeSection.defaultProps = {
  schedulingToVirtual: true,
  formFieldsOnly: false,
};

VSORepresentativeSection.propTypes = {
  hearing: PropTypes.object,
  errors: PropTypes.object,
  readOnly: PropTypes.bool,
  fullWidth: PropTypes.bool,
  appellantTitle: PropTypes.string,
  showTimezoneField: PropTypes.bool,
  userCanCollectVideoCentralEmails: PropTypes.bool,
  schedulingToVirtual: PropTypes.bool,
  showDivider: PropTypes.bool,
  formFieldsOnly: PropTypes.bool,
  representativeEmailAddress: PropTypes.string,
  representativeTimezone: PropTypes.string,
  currentUserTimezone: PropTypes.string,
  update: PropTypes.func,
  actionType: PropTypes.string,
  hearingDayDate: PropTypes.string
};
