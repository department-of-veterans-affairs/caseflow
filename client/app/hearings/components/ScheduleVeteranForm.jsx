/* eslint-disable camelcase */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  TRAVEL_BOARD_HEARING,
  VIDEO_HEARING,
  VIRTUAL_HEARING,
  CENTRAL_OFFICE_HEARING,
  HEARING_CONVERSION_TYPES
} from '../constants';
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

export const ScheduleVeteranForm = ({
  virtual,
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
  const availableHearingLocations = orderBy(appeal?.availableHearingLocations || [], ['distance'], ['asc']);
  const dynamic = ro !== appeal?.closestRegionalOffice || isEmpty(appeal?.availableHearingLocations);

  const getOriginalRequestType = () => {
    if (appeal?.readableOriginalHearingRequestType === TRAVEL_BOARD_HEARING) {
      // For COVID-19, travel board appeals can have either a video or virtual hearing scheduled. In this case,
      // we consider a travel board hearing as a video hearing, which enables both video and virtual options in
      // the HearingTypeDropdown
      return VIDEO_HEARING;
    }

    // The default is video hearing if the appeal isn't associated with an RO.
    return appeal?.readableOriginalHearingRequestType ?? VIDEO_HEARING;
  };
  const originalRequestType = getOriginalRequestType();
  const video = originalRequestType === VIDEO_HEARING;

  const handleChange = () => {
    if (virtual) {
      // Change the hearing form to recalculate the regional office hearing days
      return props.onChange('assignHearing', {
        virtualHearing: null,
        regionalOffice: appeal.closestRegionalOffice,
        hearingDay: {}
      });
    }

    // Set the form to contain central office hearing days
    return props.onChange('assignHearing', {
      virtualHearing: { status: 'pending' },
      regionalOffice: 'C',
      hearingDay: {}
    });
  };

  useEffect(
    () => {
      // Initializing a virtual hearing object when the initial request type is virtual to
      // auto-select the virtual option in the HearingTypeDropdown.
      if (!virtual) {
        handleChange();
      }
    },
    []
  );

  return (
    <React.Fragment>
      <div className="usa-width-one-half">
        <HearingTypeDropdown
          enableFullPageConversion
          update={handleChange}
          originalRequestType={originalRequestType}
          virtualHearing={hearing?.virtualHearing}
        />
      </div>
      <div className="cf-help-divider usa-width-one-whole" />
      {virtual ? (
        <React.Fragment>

          <div className="usa-width-one-half">
            <ReadOnly spacing={0} label="Regional Office" text={CENTRAL_OFFICE_HEARING} />
            <ReadOnly spacing={15} label="Hearing Location" text="Virtual" />

            <HearingDateDropdown
              errorMessage={errors?.hearingDay}
              key={`hearingDate__${ro}`}
              regionalOffice={ro}
              value={hearing?.hearingDay || initialHearingDate}
              onChange={(hearingDay) => props.onChange('assignHearing', { hearingDay })}
            />
            <HearingTime
              vertical
              errorMessage={errors?.scheduledTimeString}
              label="Hearing Time"
              enableZone
              onChange={(scheduledTimeString) => props.onChange('assignHearing', { scheduledTimeString })}
              value={hearing?.scheduledTimeString}
            />
          </div>
          <div className="usa-width-one-whole" {...marginTop(25)}>
            <AppellantSection
              virtual={virtual}
              errors={errors}
              video={video}
              update={(_, virtualHearing) =>
                props.onChange('assignHearing', {
                  virtualHearing: {
                    ...hearing?.virtualHearing,
                    ...virtualHearing,
                  }
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
                props.onChange('assignHearing', {
                  virtualHearing: {
                    ...hearing?.virtualHearing,
                    ...virtualHearing,
                  }
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
            onChange={(regionalOffice) => props.onChange('assignHearing', { regionalOffice })}
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
                onChange={(hearingLocation) => props.onChange('assignHearing', { hearingLocation })}
                dynamic={dynamic}
                staticHearingLocations={availableHearingLocations}
              />
              <HearingDateDropdown
                errorMessage={errors?.hearingDay}
                key={`hearingDate__${ro}`}
                regionalOffice={ro}
                value={hearing.hearingDay || initialHearingDate}
                onChange={(hearingDay) => props.onChange('assignHearing', { hearingDay })}
              />
              <HearingTime
                regionalOffice={ro}
                errorMessage={errors?.scheduledTimeString}
                vertical
                label="Hearing Time"
                enableZone
                onChange={(scheduledTimeString) => props.onChange('assignHearing', { scheduledTimeString })}
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
};

/* eslint-enable camelcase */
