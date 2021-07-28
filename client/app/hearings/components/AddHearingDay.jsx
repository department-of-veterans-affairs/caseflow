import { bindActionCreators } from 'redux';
import { debounce, pickBy, isEmpty, filter } from 'lodash';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import React, { useState, useEffect } from 'react';
import { connect } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { HearingTime } from './modalForms/HearingTime';
import moment from 'moment-timezone';

import { DocketStartTimes } from './DocketStartTimes';
import {
  RegionalOfficeDropdown,
  HearingCoordinatorDropdown,
  JudgeDropdown
} from '../../components/DataDropdowns';
import { fullWidth } from '../../queue/constants';
import { onRegionalOfficeChange } from '../../components/common/actions';
import {
  onSelectedHearingDayChange,
  selectRequestType,
  onAssignHearingRoom,
  onReceiveHearingSchedule
} from '../actions/hearingScheduleActions';
import {
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onSuccessfulHearingDayCreate,
} from '../actions/dailyDocketActions';
import Alert from '../../components/Alert';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import Checkbox from '../../components/Checkbox';
import DateSelector from '../../components/DateSelector';
import {
  saveButton,
  cancelButton,
  notesFieldStyling,
  roomRequiredStyling,
  statusMsgTitleStyle,
  statusMsgDetailStyle,
} from './details/style';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import { TimeSlotCount } from '../../components/DataDropdowns/TimeSlotCount';
import { TimeSlotLength } from '../../components/DataDropdowns/TimeSlotLength';
import HEARING_REQUEST_TYPES from '../../../constants/HEARING_REQUEST_TYPES';
import { REQUEST_TYPE_OPTIONS } from '../constants';
import { TimeSlot } from './scheduleHearing/TimeSlot';

export const AddHearingDay = ({
  history,
  requestType, selectedHearingDay, vlj, coordinator, notes, roomRequired, selectedRegionalOffice,
  hearingSchedule, user, ...props
}) => {
  const [hearingStartTime, setHearingStartTime] = useState(null);
  const [slotLength, setSlotLength] = useState(null);
  const [slotCount, setSlotCount] = useState(null);

  const [selectedRequestType, setSelectedRequestType] = useState(requestType?.value || null);
  const [serverError, setServerError] = useState(false);
  const [noRoomsAvailableError, setNoRoomsAvailableError] = useState(false);
  const [errorMessages, setErrorMessages] = useState({});
  const [loading, setLoading] = useState(false);

  const selectedVirtual = selectedRequestType === HEARING_REQUEST_TYPES.virtual;
  const selectedVideo = selectedRequestType === HEARING_REQUEST_TYPES.video;

  const dateError = errorMessages?.noDate || errorMessages?.invalidDate;

  // Determine whether to display the time slots
  const showTimeSlots = selectedVirtual && !isEmpty(selectedRegionalOffice) && selectedHearingDay;

  // Determine the Eastern Time Zone offset
  const zoneOffset = moment(selectedHearingDay).isDST() ? '04:00' : '05:00';

  useEffect(() => {
    // Initialize the Time slot variables based on the selected request type and valid form fields
    if (showTimeSlots) {
      setHearingStartTime('08:30');
      setSlotLength(60);
      setSlotCount(8);
    } else {
      setHearingStartTime(null);
      setSlotLength(null);
      setSlotCount(null);
    }
  }, [selectedRequestType, selectedRegionalOffice, selectedHearingDay]);

  const handleStartTimeChange = (value) => {
    setHearingStartTime(value);
  };

  const handleSlotLengthChange = (value) => {
    setSlotLength(Number(value));
  };

  const handleSlotCountChange = (value) => {
    setSlotCount(Number(value));
  };

  const submitHearingDay = () => {
    const data = {
      request_type: requestType.value,
      scheduled_for: selectedHearingDay,
      number_of_slots: slotCount,
      first_slot_time: hearingStartTime,
      slot_length_minutes: slotLength,
      judge_id: vlj.value,
      bva_poc: coordinator.value,
      notes,
      assign_room: selectedVirtual ? false : roomRequired,
      ...(selectedRegionalOffice?.key !== '' && requestType?.value !== 'C' && {
        regional_office: selectedRegionalOffice?.key
      })
    };

    ApiUtil.post('/hearings/hearing_day.json', { data }).
      then((response) => {
        const resp = ApiUtil.convertToCamelCase(response?.body);

        const newHearings = Object.assign({}, hearingSchedule);
        const hearingsLength = Object.keys(newHearings).length;

        newHearings[hearingsLength] = resp?.hearing;

        props.onReceiveHearingSchedule(newHearings);
        props.onSuccessfulHearingDayCreate(selectedHearingDay);
        history.push('/schedule');
      }, (error) => {
        // Reset the loading state on error
        setLoading(false);

        if (error?.response?.body && error.response.body.errors &&
        error.response.body.errors[0].status === 400) {
          setNoRoomsAvailableError(error.response.body.errors[0]);
        } else {
        // All other server errors
          setServerError(true);
        }
      });
  };

  const videoHearingDateNotValid = (hearingDate) => {
    const integerDate = parseInt(hearingDate?.split('-').join(''), 10);

    return integerDate < 20190401;
  };

  const onClickConfirm = () => {
    setLoading(true);
    setServerError(false);
    setNoRoomsAvailableError(false);

    const errorMsgs = {
      ...(selectedHearingDay === '' && { noDate: 'Please make sure you have entered a Hearing Date' }),
      ...(selectedVideo && videoHearingDateNotValid(selectedHearingDay) &&
      {
        invalidDate: 'Video hearing days cannot be scheduled for prior than April 1st through Caseflow.'
      }),
      ...(requestType === '' && { requestType: 'Please make sure you have entered a Hearing Type' }),
      ...(selectedVideo && !selectedRegionalOffice?.key && { ro: 'Please make sure you select a Regional Office' })
    };

    if (!isEmpty(errorMsgs)) {
      setLoading(false);
      setErrorMessages(errorMsgs);

      return;
    }

    submitHearingDay();
  };

  const resetErrorState = debounce(() => {
    setErrorMessages({});
  }, 250);

  const onHearingDateChange = (option) => {
    props.onSelectedHearingDayChange(option);
    resetErrorState();
  };

  const onRoChange = (option) => {
    props.onRegionalOfficeChange(option);
    resetErrorState();
  };

  const onRequestTypeChange = (value) => {
    props.selectRequestType(value);
    resetErrorState();

    switch ((value || {}).value) {
    case HEARING_REQUEST_TYPES.video:
    case HEARING_REQUEST_TYPES.central:
    case HEARING_REQUEST_TYPES.virtual:
      setSelectedRequestType(value.value);
      break;
    default:
      setSelectedRequestType(null);
    }
  };

  const showAlert = serverError || noRoomsAvailableError;

  const alertTitle = noRoomsAvailableError ? noRoomsAvailableError?.title : 'An error has occurred';

  const alertMessage = noRoomsAvailableError ? noRoomsAvailableError?.detail :
    'You are unable to complete this action.';

  const getErrorMessage = (roError = false) => {
    const errorMsgTitle = roError ? 'Hearing type is a Video hearing' :
      'Cannot create a New Hearing Day';

    const errorMsgs = roError ? pickBy(errorMessages, (_value, key) => key === 'ro') :
      pickBy(errorMessages, (_value, key) => key !== 'ro');

    return <div>
      <span {...statusMsgTitleStyle}>{errorMsgTitle}</span>
      <ul {...statusMsgDetailStyle} >
        {
          Object.values(errorMsgs).map((item, i) => <li key={i}>{item}</li>)
        }
      </ul></div>;
  };

  const filteredRequestTypeOptions = (options) => {
    if (user?.userCanAddVirtualHearingDays) {
      return options;
    }

    return filter(options, (option) => option.value !== HEARING_REQUEST_TYPES.virtual);
  };

  return (
    <React.Fragment>
      <AppSegment filledBackground >
        <div {...fullWidth} className="hearing-day-container">
          <h1>Add a Hearing Day</h1>
          {showAlert && <Alert type="error" title={alertTitle} scrollOnAlert={false}> {alertMessage} </Alert>}
          <DateSelector
            className={['hearing-day-date']}
            name="hearingDate"
            label={<b>Docket Date</b>}
            errorMessage={dateError ? getErrorMessage() : null}
            value={selectedHearingDay}
            onChange={onHearingDateChange}
            type="date"
          />
          <SearchableDropdown
            name="requestType"
            label="Type of Docket"
            strongLabel
            errorMessage={!dateError && errorMessages?.requestType ? getErrorMessage() : null}
            value={requestType}
            onChange={onRequestTypeChange}
            options={filteredRequestTypeOptions(REQUEST_TYPE_OPTIONS)}
          />
          <Checkbox
            name="roomRequired"
            label="Assign a Board hearing room"
            disabled={selectedVirtual}
            strongLabel
            value={selectedVirtual ? false : roomRequired}
            onChange={(value) => props.onAssignHearingRoom(value)}
            {...roomRequiredStyling}
          />
          {selectedVideo &&
            <DocketStartTimes
              setSlotCount={setSlotCount}
              setHearingStartTime={setHearingStartTime}
              hearingStartTime={hearingStartTime}
              roTimezone={selectedRegionalOffice?.timezone || 'America/New_York'}
            />
          }
          {(selectedVideo || selectedVirtual) && (
            <RegionalOfficeDropdown
              label="Regional Office (RO)"
              excludeVirtualHearingsOption={!selectedVirtual}
              errorMessage={errorMessages?.ro ? getErrorMessage(true) : null}
              onChange={onRoChange}
              value={selectedRegionalOffice?.key}
            />
          )}
          {selectedRequestType !== null && (
            <React.Fragment>
              <JudgeDropdown
                optional
                name="vlj"
                label="VLJ"
                value={vlj?.value}
                onChange={(value, label) => props.selectVlj({ value, label })}
              />
              <HearingCoordinatorDropdown
                optional
                name="coordinator"
                label="Hearing Coordinator"
                value={coordinator?.value}
                onChange={(value, label) => props.selectHearingCoordinator({ value, label })}
              />
            </React.Fragment>
          )}
          <TextareaField
            optional
            name="Notes"
            strongLabel
            onChange={(value) => props.setNotes(value)}
            textAreaStyling={notesFieldStyling}
            value={notes}
          />
          {showTimeSlots && (
            <React.Fragment>
              <div className="cf-help-divider usa-width-one-whole" />
              <TimeSlotCount onChange={(value) => handleSlotCountChange(value)} value={slotCount} />
              <TimeSlotLength onChange={(value) => handleSlotLengthChange(value)} value={slotLength} />
              <HearingTime
                disableRadioOptions
                regionalOffice={selectedRegionalOffice?.key}
                vertical
                label="Start Time of Slots"
                enableZone
                localZone="America/New_York"
                onChange={handleStartTimeChange}
                value={hearingStartTime}
              />
              <div className="time-slot-preview-container">
                <TimeSlot
                  {...props}
                  disableToggle
                  preview
                  slotStartTime={`${selectedHearingDay}T${hearingStartTime}:00-${zoneOffset}`}
                  slotLength={slotLength}
                  slotCount={slotCount}
                  hearingDate={selectedHearingDay}
                  label="Preview Time Slots"
                  ro={selectedRegionalOffice.key}
                  roTimezone={selectedRegionalOffice?.timezone}
                />
              </div>

            </React.Fragment>
          )}
        </div>
      </AppSegment>
      <Button
        name="Cancel"
        linkStyling
        onClick={() => {
          window.analyticsEvent('Hearings', 'Add Hearing Day - Cancel');
          history.push('/schedule');
        }}
        styling={cancelButton}
      >
          Cancel
      </Button>
      <span {...saveButton}>
        <Button
          name="Add Hearing Day"
          loading={loading}
          className="usa-button"
          onClick={onClickConfirm}
        >
          Add Hearing Day
        </Button>
      </span>
    </React.Fragment>
  );
};

AddHearingDay.propTypes = {
  onSuccessfulHearingDayCreate: PropTypes.func,
  history: PropTypes.object,
  coordinator: PropTypes.shape({
    value: PropTypes.string
  }),
  hearingSchedule: PropTypes.object,
  notes: PropTypes.string,
  onAssignHearingRoom: PropTypes.func,
  onReceiveHearingSchedule: PropTypes.func,
  onRegionalOfficeChange: PropTypes.func,
  onSelectedHearingDayChange: PropTypes.func,
  requestType: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.shape({
      value: PropTypes.string
    })
  ]),
  roomRequired: PropTypes.bool,
  selectHearingCoordinator: PropTypes.func,
  selectRequestType: PropTypes.func,
  selectVlj: PropTypes.func,
  selectedHearingDay: PropTypes.string,

  // Selected Regional Office (See onRegionalOfficeChange).
  selectedRegionalOffice: PropTypes.object,

  setNotes: PropTypes.func,
  vlj: PropTypes.shape({
    value: PropTypes.string
  }),
  user: PropTypes.object
};

const mapStateToProps = (state) => ({
  hearingSchedule: state.hearingSchedule.hearingSchedule,
  selectedRegionalOffice: state.components.selectedRegionalOffice || {},
  selectedHearingDay: state.hearingSchedule.selectedHearingDay,
  requestType: state.hearingSchedule.requestType,
  vlj: state.hearingSchedule.vlj || {},
  coordinator: state.hearingSchedule.coordinator || {},
  notes: state.hearingSchedule.notes,
  roomRequired: state.hearingSchedule.roomRequired
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onSuccessfulHearingDayCreate,
  onSelectedHearingDayChange,
  onRegionalOfficeChange,
  selectRequestType,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onAssignHearingRoom,
  onReceiveHearingSchedule
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddHearingDay));
