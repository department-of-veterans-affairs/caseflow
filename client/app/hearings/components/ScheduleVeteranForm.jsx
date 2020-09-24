/* eslint-disable camelcase */
import React from 'react';
import PropTypes from 'prop-types';
import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown
} from '../../components/DataDropdowns';
import { AddressLine } from './details/Address';
import { ReadOnly } from './details/ReadOnly';
import HearingTypeDropdown from './details/HearingTypeDropdown';
import { HearingTime } from './modalForms/HearingTime';
import { RepresentativeSection } from './VirtualHearings/RepresentativeSection';
import { AppellantSection } from './VirtualHearings/AppellantSection';
import { marginTop } from './details/style';
import { isEmpty, orderBy } from 'lodash';
import HEARING_REQUEST_TYPES from
  '../../../constants/HEARING_REQUEST_TYPES';

export const ScheduleVeteranForm = ({
  virtual,
  requestType,
  appellantTitle,
  appeal,
  hearing,
  errors,
  initialRegionalOffice,
  initialHearingDate,
  ...props
}) => {
  const ro = hearing?.regionalOffice || initialRegionalOffice;
  const location = hearing?.hearingLocation || appeal?.hearingLocation;
  const video = requestType === 'Video';
  const availableHearingLocations = orderBy(appeal?.availableHearingLocations || [], ['distance'], ['asc']);
  const dynamic = ro !== appeal?.closestRegionalOffice || isEmpty(appeal?.availableHearingLocations);

  const handleChange = () => {
    if (virtual) {
      return props.onChange('virtualHearing', null);
    }

    return props.onChange('virtualHearing', { status: 'pending' });
  };

  return (
    <React.Fragment>
      <div className="usa-width-one-half">
        <HearingTypeDropdown
          enableFullPageConversion
          update={handleChange}
          requestType={hearing?.requestType}
          virtualHearing={hearing?.virtualHearing}
        />
      </div>
      <div className="cf-help-divider usa-width-one-whole" />
      {virtual ? (
        <React.Fragment>

          <div className="usa-width-one-half">
            <ReadOnly spacing={0} label="Regional Office" text={HEARING_REQUEST_TYPES.central} />
            <ReadOnly spacing={15} label="Hearing Location" text="Virtual" />

            <HearingDateDropdown
              errorMessage={errors?.hearingDay}
              key={`hearingDate__${ro}`}
              regionalOffice={ro}
              value={hearing?.hearingDay || initialHearingDate}
              onChange={(hearingDay) => props.onChange('hearingDay', hearingDay)}
            />
            <HearingTime
              vertical
              errorMessage={errors?.scheduledTimeString}
              label="Hearing Time"
              enableZone
              onChange={(scheduledTimeString) => props.onChange('scheduledTimeString', scheduledTimeString)}
              value={hearing?.scheduledTimeString}
            />
          </div>
          <div className="usa-width-one-whole" {...marginTop(25)}>
            <AppellantSection
              virtual={virtual}
              errors={errors}
              video={video}
              update={(_, virtualHearing) =>
                props.onChange('virtualHearing', {
                  ...hearing?.virtualHearing,
                  ...virtualHearing,
                })
              }
              appellantTitle={appellantTitle}
              hearing={hearing}
              virtualHearing={hearing?.virtualHearing}
              type={HEARING_CONVERSION_TYPES[0]}
            />
            <RepresentativeSection
              virtual={virtual}
              errors={errors}
              video={video}
              update={(_, virtualHearing) =>
                props.onChange('virtualHearing', {
                  ...hearing?.virtualHearing,
                  ...virtualHearing,
                })
              }
              appellantTitle={appellantTitle}
              hearing={hearing}
              virtualHearing={hearing?.virtualHearing}
              type={HEARING_CONVERSION_TYPES[0]}
            />
          </div>
        </React.Fragment>
      ) : (
        <div className="usa-width-one-half" >
          <ReadOnly spacing={0} label={`${appellantTitle} Address`} text={
            <AddressLine
              spacing={5}
              name={appeal?.appellantFullName}
              addressLine1={appeal?.appellantAddress?.address_line_1}
              addressState={appeal?.appellantAddress?.state}
              addressCity={appeal?.appellantAddress?.city}
              addressZip={appeal?.appellantAddress?.zip}
            />}
          />
          <RegionalOfficeDropdown
            errorMessage={errors?.regionalOffice}
            onChange={(regionalOffice) => props.onChange('regionalOffice', regionalOffice)}
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
                onChange={(hearingLocation) => props.onChange('hearingLocation', hearingLocation)}
                dynamic={dynamic}
                staticHearingLocations={availableHearingLocations}
              />
              <HearingDateDropdown
                errorMessage={errors?.hearingDay}
                key={`hearingDate__${ro}`}
                regionalOffice={ro}
                value={hearing.hearingDay || initialHearingDate}
                onChange={(hearingDay) => props.onChange('hearingDay', hearingDay)}
              />
              <HearingTime
                regionalOffice={ro}
                errorMessage={errors?.scheduledTimeString}
                vertical
                label="Hearing Time"
                enableZone
                onChange={(scheduledTimeString) => props.onChange('scheduledTimeString', scheduledTimeString)}
                value={hearing.scheduledTimeString}
              />

            </React.Fragment>
          )}
        </div>)}
    </React.Fragment>
  );
};

ScheduleVeteranForm.propTypes = {
  virtual: PropTypes.bool,
  loading: PropTypes.bool,
  onChange: PropTypes.func.isRequired,
  appeal: PropTypes.object,
  errors: PropTypes.object,
  hearing: PropTypes.object,
  initialRegionalOffice: PropTypes.string,
  initialHearingDate: PropTypes.string,
  appellantTitle: PropTypes.string,
  requestType: PropTypes.string
};

/* eslint-enable camelcase */
