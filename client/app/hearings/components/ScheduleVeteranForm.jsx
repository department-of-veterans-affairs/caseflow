/* eslint-disable camelcase */
import React from 'react';
import PropTypes from 'prop-types';
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
import { ReadOnlyHearingTimeWithZone } from './modalForms/ReadOnlyHearingTimeWithZone';
import { RepresentativeSection } from './VirtualHearings/RepresentativeSection';
import { AppellantSection } from './VirtualHearings/AppellantSection';
import { marginTop } from './details/style';
import { isEmpty, orderBy } from 'lodash';
import { TimeSlot } from './scheduleHearing/TimeSlot';
import { useDispatch } from 'react-redux';
import { fetchScheduledHearings } from '../../components/common/actions';
import { AppealInformation } from './scheduleHearing/AppealInformation';
import { UnscheduledNotes } from './UnscheduledNotes';
import { formatNotificationLabel } from '../utils';

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
  userCanCollectVideoCentralEmails,
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

  const hearingDayIsVideo = hearing?.hearingDay?.readableRequestType === 'Video';
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
    userCanCollectVideoCentralEmails,
    showDivider: false,
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

  const getHearingTime = () => {
    const onTimeChange =
      (scheduledTimeString) => props.onChange('scheduledTimeString', scheduledTimeString);

    if (hearingDayIsVideo && hearing.hearingDay?.beginsAt) {
      return (
        <ReadOnlyHearingTimeWithZone
          hearingStartTime={hearing.hearingDay?.beginsAt}
          timezone={hearing?.hearingDay?.timezone}
          onRender={onTimeChange}
        />
      );
    }

    return <HearingTime
      regionalOffice={ro}
      errorMessage={errors?.scheduledTimeString}
      vertical
      label="Hearing Time"
      enableZone
      localZone={hearing?.hearingDay?.timezone}
      onChange={onTimeChange}
      value={hearing.scheduledTimeString}
    />;

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
            virtualHearing={virtual ? { status: 'pending' } : null}
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
          <div {...marginTop(30)}>
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
                <div {...marginTop(30)}>
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
              <div {...marginTop(30)}>
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
                <div {...marginTop(30)}>
                  {hearingDayIsVirtual && userCanViewTimeSlots ? (
                    <TimeSlot
                      {...props}
                      ro={ro}
                      onChange={props.onChange}
                      hearing={hearing}
                      roTimezone={hearing?.hearingDay?.timezone}
                    />
                  ) : (
                    getHearingTime()
                  )}
                </div>
              )}
            </React.Fragment>
          )}
        </div>
        {(userCanCollectVideoCentralEmails || virtual) && (
          <React.Fragment>
            <div className="cf-help-divider usa-width-one-whole" />
            <div className="usa-width-one-whole" >
              <h2>Email Notifications {!virtual && '(Optional)'}</h2>
              <p>{formatNotificationLabel(hearing, virtual, appellantTitle)}</p>
              <AppellantSection
                {...sectionProps}
                virtual={virtual}
                showTimezoneField={userCanCollectVideoCentralEmails}
                fullWidth
              />
              <RepresentativeSection
                {...sectionProps}
                virtual={virtual}
                showTimezoneField={userCanCollectVideoCentralEmails}
                fullWidth
              />
            </div>
          </React.Fragment>
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
  userCanCollectVideoCentralEmails: PropTypes.bool,
  hearingTask: PropTypes.object
};

/* eslint-enable camelcase */
