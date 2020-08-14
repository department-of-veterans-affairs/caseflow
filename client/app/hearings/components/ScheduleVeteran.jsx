/* eslint-disable camelcase */
import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown
} from '../../components/DataDropdowns';
import { AddressLine } from './details/Address';
import { getAppellantTitleForHearing } from '../utils';
import { ReadOnly } from './details/ReadOnly';
import HearingTypeDropdown from './details/HearingTypeDropdown';
import { marginTop, regionalOfficeSection } from './details/style';
import { HearingTime } from './modalForms/HearingTime';
import Button from '../../components/Button';
import { css } from 'glamor';
import { RepresentativeSection } from './VirtualHearings/RepresentativeSection';
import { AppellantSection } from './VirtualHearings/AppellantSection';
import { HEARING_CONVERSION_TYPES } from '../constants';

export const ScheduleVeteran = ({ appeal, hearing, errors, ...props }) => {
  const appellantTitle = getAppellantTitleForHearing(hearing);
  const ro = appeal.regionalOffice || hearing.regionalOffice;
  const location = appeal.hearingLocation || hearing.location;
  const header = `Schedule ${appellantTitle} for a Hearing`;
  const virtual = hearing?.virtualHearing;
  const video = hearing?.readableRequestType === 'Video';

  const handleChange = () => {
    if (virtual) {
      return props.onChange('hearing', { virtualHearing: null });
    }

    return props.onChange('hearing', { virtualHearing: { status: 'pending' } });
  };

  return (
    <div {...regionalOfficeSection}>
      <AppSegment filledBackground >
        <h1>{header}</h1>
        <div {...marginTop(45)} />
        <div className="usa-width-one-half">
          <HearingTypeDropdown
            enableFullPageConversion
            update={handleChange}
            requestType={hearing.readableRequestType}
            virtualHearing={hearing?.virtualHearing}
          />
        </div>
        <div className="cf-help-divider usa-width-one-whole" />
        {virtual ? (
          <React.Fragment>

            <div className="usa-width-one-half" >
              <ReadOnly spacing={0} label="Regional Office" text={appeal.regionalOffice} />
              <ReadOnly spacing={15} label="Hearing Location" text={appeal.hearingLocation?.name} />

            </div>
            <div {...marginTop(15)} className="usa-width-one-half">
              <HearingDateDropdown
                errorMessage={errors?.hearingDay}
                key={`hearingDate__${ro}`}
                regionalOffice={ro}
                value={appeal.hearingDay}
                onChange={(hearingDay) => props.onChange('appeal', { hearingDay })}
              />
            </div>
            <div {...marginTop(15)} className="usa-width-one-half" >
              <HearingTime
                vertical
                errorMessage={errors?.scheduledTimeString}
                label="Hearing Time"
                enableZone
                onChange={(scheduledTimeString) => props.onChange('hearing', { scheduledTimeString })}
                value={hearing.scheduledTimeString}
              />
            </div>
            <div className="cf-help-divider usa-width-one-whole" />
            <AppellantSection
              errors={errors}
              video={video}
              update={(_, virtualHearing) => props.onChange('hearing', virtualHearing)}
              appellantTitle={appellantTitle}
              hearing={hearing}
              virtualHearing={hearing?.virtualHearing}
              type={HEARING_CONVERSION_TYPES[0]}
            />
            <RepresentativeSection
              virtual
              errors={errors}
              video={video}
              update={(_, virtualHearing) => props.onChange('hearing', { virtualHearing: { ...hearing?.virtualHearing, ...virtualHearing } })}
              appellantTitle={appellantTitle}
              hearing={hearing}
              virtualHearing={hearing?.virtualHearing}
              type={HEARING_CONVERSION_TYPES[0]}
            />
          </React.Fragment>
        ) : (
          <div className="usa-width-one-half">
            <div >
              <ReadOnly spacing={0} label={`${appellantTitle} Address`} text={
                <AddressLine
                  spacing={5}
                  name={appeal?.veteranInfo?.veteran?.full_name}
                  addressLine1={appeal?.veteranInfo?.veteran?.address?.address_line_1}
                  addressState={appeal?.veteranInfo?.veteran?.address?.state}
                  addressCity={appeal?.veteranInfo?.veteran?.address?.city}
                  addressZip={appeal?.veteranInfo?.veteran?.address?.zip}
                />}
              />
            </div>
            <RegionalOfficeDropdown
              onChange={(regionalOffice) => props.onChange('appeal', { regionalOffice })}
              value={ro}
              validateValueOnMount
            />
            {ro && (
              <React.Fragment>
                <AppealHearingLocationsDropdown
                  errorMessage={errors?.hearingLocation}
                  key={`hearingLocation__${ro}`}
                  regionalOffice={ro}
                  appealId={appeal.externalId}
                  value={location}
                  onChange={(hearingLocation) => props.onChange('appeal', { hearingLocation })}
                />
                <HearingDateDropdown
                  errorMessage={errors?.hearingDay}
                  key={`hearingDate__${ro}`}
                  regionalOffice={ro}
                  value={appeal.hearingDay}
                  onChange={(hearingDay) => props.onChange('appeal', { hearingDay })}
                />
                <HearingTime
                  errorMessage={errors?.scheduledTimeString}
                  vertical
                  label="Hearing Time"
                  enableZone
                  onChange={(scheduledTimeString) => props.onChange('hearing', { scheduledTimeString })}
                  value={hearing.scheduledTimeString}
                />

              </React.Fragment>
            )}
          </div>)}
      </AppSegment>
      <Button
        name="Cancel"
        linkStyling
        onClick={() => props.goBack()}
        styling={css({ float: 'left', paddingLeft: 0, paddingRight: 0 })}
      >
          Cancel
      </Button>
      <span {...css({ float: 'right' })}>
        <Button
          name="Schedule"
          loading={props.loading}
          className="usa-button"
          onClick={() => props.submit()}
        >
          Schedule
        </Button>
      </span>
    </div>
  );
};

ScheduleVeteran.propTypes = {
  loading: PropTypes.bool,
  submit: PropTypes.func.isRequired,
  goBack: PropTypes.func.isRequired,
  onChange: PropTypes.func.isRequired,
  appeal: PropTypes.object,
  errors: PropTypes.object,
  hearing: PropTypes.object
};

/* eslint-enable camelcase */
