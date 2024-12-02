/* eslint-disable camelcase */
import React from 'react';
import PropTypes from 'prop-types';
import { HEARING_CONVERSION_TYPES } from '../constants';
import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown,
} from '../../components/DataDropdowns';
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
  initialHearingDay,
  userCanViewTimeSlots,
  hearingTask,
  userCanCollectVideoCentralEmails,
  hearingRequestTypeDropdownOptions,
  hearingRequestTypeDropdownCurrentOption,
  hearingRequestTypeDropdownOnchange,
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
  const hearingDayIsVirtual = hearing?.requestType === 'Virtual';

  const hearingDayIsVideo = hearing?.requestType === 'Video';

  const hearingDayDate = hearing.hearingDay?.scheduledFor || initialHearingDay?.scheduledFor;

  // Set the section props
  const sectionProps = {
    errors,
    hearing,
    appellantTitle,
    userCanCollectVideoCentralEmails,
    formFieldsOnly: true,
    showDivider: false,
    schedulingToVirtual: virtual,
    virtualHearing: hearing?.virtualHearing,
    type: HEARING_CONVERSION_TYPES[0],
    showTimezoneField: true,
    appellantEmailAddress: hearing?.virtualHearing?.appellantEmail,
    appellantTimezone: hearing?.virtualHearing?.appellantTz,
    representativeEmailAddress: hearing?.virtualHearing?.representativeEmail,
    representativeTimezone: hearing?.virtualHearing?.representativeTz,
    appellantEmailType: 'appellantEmail',
    representativeEmailType: 'representativeEmail',
    update: (_, virtualHearing) =>
      props.onChange('virtualHearing', {
        ...hearing?.virtualHearing,
        ...virtualHearing,
      }),
    hearingDayDate
  };

  const getHearingTime = () => {
    const onTimeChange =
      (scheduledTimeString) => props.onChange('scheduledTimeString', scheduledTimeString);

    if (hearingDayIsVideo && hearing.hearingDay?.halfDay) {
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
      requestType={hearing?.hearingDay?.readableRequestType}
      errorMessage={errors?.scheduledTimeString}
      vertical
      label="Hearing Time"
      enableZone
      localZone={hearing?.hearingDay?.timezone}
      onChange={onTimeChange}
      value={hearing.scheduledTimeString}
      hearingDayDate={hearingDayDate}
    />;

  };

  return (
    <div className="usa-width-one-whole schedule-veteran-details" data-testid="schedule-veteran-form" >
      <div className="usa-width-one-fourth schedule-veteran-appeal-info-container">
        <AppealInformation appeal={appeal} appellantTitle={appellantTitle} hearing={hearing} />
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
            dropdownOptions={hearingRequestTypeDropdownOptions}
            currentOption={hearingRequestTypeDropdownCurrentOption}
            onChange={hearingRequestTypeDropdownOnchange}
          />
        </div>
        <div className="usa-width-one-whole" {...marginTop(30)}>
          {virtual && (
            <ReadOnly spacing={15} label="Hearing Location" text="Virtual" />
          )}
          <div {...marginTop(30)}>
            <RegionalOfficeDropdown
              id="regional-office"
              aria-labelledby="regional-office-label"
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
                  value={hearing.hearingDay || initialHearingDay}
                  onChange={(hearingDay) => {
                    // Call fetch scheduled hearings only if passed
                    fetchScheduledHearings(hearingDay)(dispatch);

                    props.onChange('hearingDay', hearingDay);
                  }}
                />
              </div>
              {hearing.hearingDay?.scheduledFor && (
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
              <AppellantSection {...sectionProps} fullWidth />
              <RepresentativeSection {...sectionProps} fullWidth />
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
  initialHearingDay: PropTypes.object,
  appellantTitle: PropTypes.string,
  fetchScheduledHearings: PropTypes.func,
  userCanViewTimeSlots: PropTypes.bool,
  userCanCollectVideoCentralEmails: PropTypes.bool,
  hearingTask: PropTypes.object,
  hearingRequestTypeDropdownOptions: PropTypes.array,
  hearingRequestTypeDropdownCurrentOption: PropTypes.object,
  hearingRequestTypeDropdownOnchange: PropTypes.func
};

/* eslint-enable camelcase */
