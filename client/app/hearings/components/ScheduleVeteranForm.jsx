/* eslint-disable camelcase */
import React from 'react';
import PropTypes from 'prop-types';
import {
  TRAVEL_BOARD_HEARING_LABEL,
  VIDEO_HEARING_LABEL,
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
  convertToVirtual,
  ...props
}) => {
  const ro = hearing?.regionalOffice || initialRegionalOffice;
  const location = hearing?.hearingLocation || appeal?.hearingLocation;
  const availableHearingLocations = orderBy(appeal?.availableHearingLocations || [], ['distance'], ['asc']);
  const dynamic = ro !== appeal?.closestRegionalOffice || isEmpty(appeal?.availableHearingLocations);

  const getOriginalRequestType = () => {
    if (appeal?.readableOriginalHearingRequestType === TRAVEL_BOARD_HEARING_LABEL) {
    // For COVID-19, travel board appeals can have either a video or virtual hearing scheduled. In this case,
    // we consider a travel board hearing as a video hearing, which enables both video and virtual options in
    // the HearingTypeDropdown
      return VIDEO_HEARING_LABEL;
    }

    // The default is video hearing if the appeal isn't associated with an RO.
    return appeal?.readableOriginalHearingRequestType ?? VIDEO_HEARING_LABEL;
  };

  // Set the hearing request to Video unless the RO is Central
  const video = ro !== 'C';

  return (
    <React.Fragment>
      <div className="usa-width-one-half">
        <HearingTypeDropdown
          enableFullPageConversion
          update={convertToVirtual}
          originalRequestType={getOriginalRequestType()}
          virtualHearing={hearing?.virtualHearing}
        />
      </div>
      <div className="cf-help-divider usa-width-one-whole" />
      <div className="usa-width-one-half">
        {virtual ? <ReadOnly spacing={15} label="Hearing Location" text="Virtual" /> :
          <ReadOnly spacing={0} label={`${appellantTitle} Address`} text={
            <AddressLine
              spacing={5}
              name={appeal?.appellantFullName}
              addressLine1={appeal?.appellantAddress?.address_line_1}
              addressState={appeal?.appellantAddress?.state}
              addressCity={appeal?.appellantAddress?.city}
              addressZip={appeal?.appellantAddress?.zip}
            />}
          /> }
        <RegionalOfficeDropdown
          errorMessage={errors?.regionalOffice}
          excludeVirtualHearingsOption
          onChange={(regionalOffice) => props.onChange('regionalOffice', regionalOffice)}
          value={ro}
          validateValueOnMount
        />
        {ro && (
          <React.Fragment>
            {!virtual && <AppealHearingLocationsDropdown
              errorMessage={errors?.hearingLocation}
              key={`hearingLocation__${ro}`}
              regionalOffice={ro}
              appealId={appeal.externalId}
              value={location}
              onChange={(hearingLocation) => props.onChange('hearingLocation', hearingLocation)}
              dynamic={dynamic}
              staticHearingLocations={availableHearingLocations}
            />}
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
              localZone={hearing?.hearingDay?.timezone}
              onChange={(scheduledTimeString) => props.onChange('scheduledTimeString', scheduledTimeString)}
              value={hearing.scheduledTimeString}
            />
          </React.Fragment>
        )}

      </div>
      {virtual && <div className="usa-width-one-whole" {...marginTop(25)}>
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
      </div>}
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
  convertToVirtual: PropTypes.func
};

/* eslint-enable camelcase */
