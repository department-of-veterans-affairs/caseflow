// External Dependencies
import PropTypes from 'prop-types';
import React, { useState } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { isEmpty } from 'lodash';
import moment from 'moment-timezone';
import { useSelector } from 'react-redux';

// Component Dependencies
import Button from 'app/components/Button';
import DateSelector from 'app/components/DateSelector';
import {
  RegionalOfficeDropdown,
  HearingCoordinatorDropdown,
  JudgeDropdown,
  HearingRoomDropdown
} from 'app/components/DataDropdowns';
import SearchableDropdown from 'app/components/SearchableDropdown';
import TextareaField from 'app/components/TextareaField';
import { HelperText } from 'app/hearings/components/VirtualHearings/HelperText';
import { TimeSlotCount } from 'app/components/DataDropdowns/TimeSlotCount';
import { TimeSlotLength } from 'app/components/DataDropdowns/TimeSlotLength';
import { TimeSlot } from 'app/hearings/components/scheduleHearing/TimeSlot';
import { HearingTime } from 'app/hearings/components/modalForms/HearingTime';
import Alert from 'app/components/Alert';

// Styles and Utils
import { saveButton, cancelButton } from 'app/hearings/components/details/style';
import { fullWidth } from 'app/queue/constants';
import { REQUEST_TYPE_OPTIONS } from 'app/hearings/constants';
import HEARING_REQUEST_TYPES from 'constants/HEARING_REQUEST_TYPES';
import ApiUtil from 'app/util/ApiUtil';
import { getRegionalOffice, readableDocketType, formatRoomOption } from 'app/hearings/utils';
import COPY from '../../../../COPY';
import { DocketStartTimes } from '../DocketStartTimes';

export const EditDocket = (props) => {
  // Initialize the state
  const { dropdowns } = useSelector((state) => state.components);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [fields, setFields] = useState({
    room: formatRoomOption(props.docket.room),
    slotLengthMinutes: props?.docket?.slotLengthMinutes,
    requestType: readableDocketType(props?.docket?.requestType),
    regionalOffice: getRegionalOffice(props.docket.regionalOfficeKey, dropdowns?.regionalOffices?.options),
    judgeId: props?.docket?.judgeId?.toString(),
    bvaPoc: props?.docket?.bvaPoc,
    notes: props?.docket?.notes,
    conferenceLink: props?.docket?.conferenceLink
  });

  // These fields need their own state since the DocketStartTimes component updates two fields
  // simultaneously, the second update overrides the first, setting one of the fields to null
  const [firstSlotTime, setFirstSlotTime] = useState(
    props?.docket?.beginsAt ? moment(props?.docket?.beginsAt).format('HH:mm') : null
  );
  const [numberOfSlots, setNumberOfSlots] = useState(props?.docket?.totalSlots);

  const [virtual, travel, central] = ['virtual', 'travel', 'central'].map((requestType) =>
    fields.requestType?.value === HEARING_REQUEST_TYPES[requestType]
  );

  const isScheduled = !isEmpty(props?.hearings);

  // -04:00 (when DST) or -05:00 for America/New_York
  const zoneOffset = moment(props?.docket?.scheduledFor).format('Z');
  const invalidDocketRo =
    fields.requestType.value !== HEARING_REQUEST_TYPES.central &&
    fields?.regionalOffice?.key === HEARING_REQUEST_TYPES.central;

  const saveEdit = () => {
    // Validate that the docket type and regional office match
    if (invalidDocketRo) {
      return;
    }

    // Reset the loading/error state
    setError(null);
    setLoading(true);

    // Format the data for the API
    const data = ApiUtil.convertToSnakeCase({
      ...fields,
      room: fields.room.value,
      regionalOffice: fields.regionalOffice.key === 'C' ? null : fields.regionalOffice.key,
      requestType: fields.requestType.value,
      firstSlotTime,
      numberOfSlots
    });

    ApiUtil.put(`/hearings/hearing_day/${props.docket.id}`, { data }).then(
      (response) => {
        // Format the data for the UI
        const editedHearingDay = {
          ...ApiUtil.convertToCamelCase(response.body),
          requestType: fields.requestType,
          conferenceLink: fields.conferenceLink
        };

        // Refresh the docket data and set the update to true so we receive the success banner
        props.updateDocket(true);
        props.refreshDocket(editedHearingDay, props.hearings);

        // Navigate back to the docket details page
        props.history.push(`/schedule/docket/${props.docket.id}`);
      },
      () => {
        setLoading(false);
        setError('You are unable to complete this action.');
      }
    );
  };

  const handleChange = (key) => (value) => {
    // If changing from Central to some other request type, regional office needs to be cleared for reselection
    if (key === 'requestType' && value?.value === HEARING_REQUEST_TYPES.central) {
      return setFields({
        ...fields,
        regionalOffice: getRegionalOffice(null),
        [key]: value
      });
    }
    // If changing the requestType to virtual, clear out the room since virtual hearings do not have assigned rooms
    if (key === 'requestType' && value?.value === HEARING_REQUEST_TYPES.virtual) {
      return setFields({
        ...fields,
        room: formatRoomOption(null),
        [key]: value
      });
    }

    return setFields({
      ...fields,
      [key]: value,
    });
  };

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <div {...fullWidth} className="hearing-day-container">
          {error && (<Alert type="error" title="An Error Occurred"> {error} </Alert>)}
          <h1>Edit Hearing Day</h1>
          <DateSelector
            inputProps={{ disabled: true }}
            className={['hearing-day-date']}
            name="hearingDate"
            label={<b>Docket Date</b>}
            value={props?.docket?.scheduledFor}
            type="date"
          />
          <SearchableDropdown
            readOnly={isScheduled}
            name="requestType"
            label="Type of Docket"
            strongLabel
            value={fields?.requestType}
            onChange={handleChange('requestType')}
            options={REQUEST_TYPE_OPTIONS}
          />
          {isScheduled && (<HelperText label={COPY.DOCKET_HAS_HEARINGS_SCHEDULED} />)}
          <RegionalOfficeDropdown
            readOnly={fields.requestType?.value === HEARING_REQUEST_TYPES.central || isScheduled}
            label="Regional Office (RO)"
            excludeVirtualHearingsOption={!virtual}
            onChange={handleChange('regionalOffice')}
            value={fields?.regionalOffice?.key}
            options={dropdowns?.regionalOffices?.options}
            errorMessage={invalidDocketRo && COPY.DOCKET_INVALID_RO_TYPE}
          />
          {!virtual && !central &&
            <DocketStartTimes
              setSlotCount={setNumberOfSlots}
              setHearingStartTime={setFirstSlotTime}
              hearingStartTime={firstSlotTime}
              amStartTime={travel ? '9:00' : '8:30'}
              pmStartTime={travel ? '13:00' : '12:30'}
              roTimezone={fields?.regionalOffice?.timezone}
            />
          }
          {!virtual && (
            <HearingRoomDropdown
              name="room"
              label="Select Room"
              value={fields.room?.value}
              onChange={(_, label) => handleChange('room')(formatRoomOption(label))}
              placeholder="Select..."
            />
          )}
          <JudgeDropdown
            label="Select VLJ"
            value={fields.judgeId}
            onChange={handleChange('judgeId')}
            placeholder="Select..."
          />
          <HearingCoordinatorDropdown
            label="Select Hearing Coordinator"
            value={fields.bvaPoc}
            onChange={handleChange('bvaPoc')}
            placeholder="Select..."
          />
          <TextareaField
            strongLabel
            name="Notes"
            onChange={handleChange('notes')}
            value={fields.notes}
          />
          {virtual && (
            <React.Fragment>
              <div className="cf-help-divider usa-width-one-whole" />
              <TimeSlotCount onChange={setNumberOfSlots} value={numberOfSlots} />
              <TimeSlotLength onChange={handleChange('slotLengthMinutes')} value={fields.slotLengthMinutes} />
              <HearingTime
                disableRadioOptions
                regionalOffice={fields?.regionalOffice?.key}
                vertical
                label="Start Time of Slots"
                enableZone
                localZone="America/New_York"
                onChange={setFirstSlotTime}
                value={firstSlotTime}
              />
              <div className="time-slot-preview-container">
                <TimeSlot
                  {...props}
                  disableToggle
                  preview
                  slotStartTime={`${props?.docket?.scheduledFor}T${firstSlotTime}:00-${zoneOffset}`}
                  slotLength={fields?.slotLengthMinutes}
                  slotCount={numberOfSlots}
                  hearingDate={props?.docket?.scheduledFor}
                  label="Preview Time Slots"
                  ro={fields.regionalOffice?.key}
                  roTimezone={fields?.regionalOffice?.timezone}
                />
              </div>
            </React.Fragment>
          )}
        </div>
      </AppSegment>
      <Button linkStyling name="Cancel" onClick={props.history.goBack} styling={cancelButton} >
        Cancel
      </Button>
      <span {...saveButton}>
        <Button name="Edit Hearing Day" loading={loading} className="usa-button" onClick={saveEdit} >
          Save Changes
        </Button>
      </span>
    </React.Fragment>
  );
};

EditDocket.propTypes = {
  history: PropTypes.object,
  docket: PropTypes.object,
  hearings: PropTypes.object,
  updateDocket: PropTypes.func,
  refreshDocket: PropTypes.func,
};

export default EditDocket;
