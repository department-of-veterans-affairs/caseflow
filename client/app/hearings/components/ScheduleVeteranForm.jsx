/* eslint-disable camelcase */
import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import {
  TRAVEL_BOARD_HEARING_LABEL,
  VIDEO_HEARING_LABEL,
  HEARING_CONVERSION_TYPES,
} from '../constants';
import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown,
} from '../../components/DataDropdowns';
import { AddressLine } from './details/Address';
import { ReadOnly } from './details/ReadOnly';
import HearingTypeDropdown from './details/HearingTypeDropdown';
import { HearingTime } from './modalForms/HearingTime';
import { RepresentativeSection } from './VirtualHearings/RepresentativeSection';
import { AppellantSection } from './VirtualHearings/AppellantSection';
import { marginTop } from './details/style';
import { isEmpty, orderBy } from 'lodash';
import { TimeSlot } from './scheduleHearing/TimeSlot';
import { useDispatch } from 'react-redux';
import { fetchScheduledHearings } from '../../components/common/actions';
import { AppealInformation } from './scheduleHearing/AppealInformation';
import { UnscheduledNotes } from './UnscheduledNotes';

export const ScheduleVeteranForm = ({
  virtual,
  appellantTitle,
  appeal,
  hearing,
  errors,
  initialRegionalOffice,
  initialHearingDate,
  convertToVirtual,
  userCanViewTimeSlots,
  hearingTask,
  ...props
}) => {
  const dispatch = useDispatch();
  const ro = hearing?.regionalOffice || initialRegionalOffice;
  const location = hearing?.hearingLocation || appeal?.hearingLocation;
  const availableHearingLocations = orderBy(
    appeal?.availableHearingLocations || [],
    ['distance'],
    ['asc']
  );
  const dynamic =
    ro !== appeal?.closestRegionalOffice ||
    isEmpty(appeal?.availableHearingLocations);

  const unscheduledNotes = hearing?.notes;
  const hearingDayIsVirtual = hearing?.hearingDay?.readableRequestType === 'Virtual';

  const getOriginalRequestType = () => {
    if (
      appeal?.readableOriginalHearingRequestType === TRAVEL_BOARD_HEARING_LABEL
    ) {
      // For COVID-19, travel board appeals can have either a video or virtual hearing scheduled. In this case,
      // we consider a travel board hearing as a video hearing, which enables both video and virtual options in
      // the HearingTypeDropdown
      return VIDEO_HEARING_LABEL;
    }

    // The default is video hearing if the appeal isn't associated with an RO.
    return appeal?.readableOriginalHearingRequestType ?? VIDEO_HEARING_LABEL;
  };

  // Set the section props
  const sectionProps = {
    errors,
    hearing,
    appellantTitle,
    schedulingToVirtual: virtual,
    virtualHearing: hearing?.virtualHearing,
    type: HEARING_CONVERSION_TYPES[0],
    showTimezoneField: true,
    update: (_, virtualHearing) =>
      props.onChange('virtualHearing', {
        ...hearing?.virtualHearing,
        ...virtualHearing,
      })
  };

  return (
    <div className="usa-width-one-whole schedule-veteran-details">
      <div className="usa-width-one-fourth schedule-veteran-appeal-info-container">
        <AppealInformation appeal={appeal} />
      </div>
      <div className="usa-width-one-half">
        <UnscheduledNotes
          onChange={(notes) => props.onChange('notes', notes)}
          unscheduledNotes={unscheduledNotes}
          updatedAt={hearingTask?.unscheduledHearingNotes?.updatedAt}
          updatedByCssId={hearingTask?.unscheduledHearingNotes?.updatedByCssId}
          uniqueId={hearingTask?.taskId}
        />
        <div className="cf-help-divider usa-width-one-whole" />
        <div className="usa-width-one-whole">
          <HearingTypeDropdown
            enableFullPageConversion
            update={convertToVirtual}
            originalRequestType={getOriginalRequestType()}
            virtualHearing={hearing?.virtualHearing}
          />
        </div>
        <div className="cf-help-divider usa-width-one-whole" />
        <div className="usa-width-one-whole">
          {virtual ? (
            <ReadOnly spacing={15} label="Hearing Location" text="Virtual" />
          ) : (
            <ReadOnly
              spacing={0}
              label={`${appellantTitle} Address`}
              text={
                <AddressLine
                  spacing={5}
                  name={appeal?.appellantFullName}
                  addressLine1={appeal?.appellantAddress?.address_line_1}
                  addressState={appeal?.appellantAddress?.state}
                  addressCity={appeal?.appellantAddress?.city}
                  addressZip={appeal?.appellantAddress?.zip}
                />
              }
            />
          )}
          <div style={{ marginTop: '30px' }}>
            <RegionalOfficeDropdown
              errorMessage={errors?.regionalOffice}
              excludeVirtualHearingsOption={!virtual}
              onChange={(regionalOffice) =>
                props.onChange('regionalOffice', regionalOffice)
              }
              value={ro}
              validateValueOnMount
            />
          </div>
          {ro && (
            <React.Fragment>
              {!virtual && (
                <div style={{ marginTop: '30px' }}>
                  <AppealHearingLocationsDropdown
                    errorMessage={errors?.hearingLocation}
                    key={`hearingLocation__${ro}`}
                    regionalOffice={ro}
                    appealId={appeal.externalId}
                    value={location}
                    onChange={(hearingLocation) =>
                      props.onChange('hearingLocation', hearingLocation)
                    }
                    dynamic={dynamic}
                    staticHearingLocations={availableHearingLocations}
                  />
                </div>
              )}
              <div style={{ marginTop: '30px' }}>
                <HearingDateDropdown
                  errorMessage={errors?.hearingDay}
                  key={`hearingDate__${ro}`}
                  regionalOffice={ro}
                  value={hearing.hearingDay || initialHearingDate}
                  onChange={(hearingDay) => {
                    // Call fetch scheduled hearings only if passed
                    fetchScheduledHearings(hearingDay)(dispatch);

                    props.onChange('hearingDay', hearingDay);
                  }}
                />
              </div>
              {hearing.hearingDay?.hearingId && (
                <div style={{ marginTop: '30px' }}>
                  {hearingDayIsVirtual && userCanViewTimeSlots ? (
                    <TimeSlot
                      {...props}
                      ro={ro}
                      onChange={props.onChange}
                      hearing={hearing}
                      roTimezone={hearing?.hearingDay?.timezone}
                    />
                  ) : (
                    <HearingTime
                      regionalOffice={ro}
                      errorMessage={errors?.scheduledTimeString}
                      vertical
                      label="Hearing Time"
                      enableZone
                      localZone={hearing?.hearingDay?.timezone}
                      onChange={(scheduledTimeString) =>
                        props.onChange('scheduledTimeString', scheduledTimeString)
                      }
                      value={hearing.scheduledTimeString}
                    />
                  )}
                </div>
              )}

            </React.Fragment>
          )}
        </div>
        {virtual && (
          <div className="usa-width-one-whole" {...marginTop(25)}>
            <AppellantSection {...sectionProps} fullWidth />
            <RepresentativeSection {...sectionProps} fullWidth />
          </div>
        )}
      </div>
    </div>
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
  convertToVirtual: PropTypes.func,
  fetchScheduledHearings: PropTypes.func,
  userCanViewTimeSlots: PropTypes.bool,
  hearingTask: PropTypes.object
};

/* eslint-enable camelcase */
