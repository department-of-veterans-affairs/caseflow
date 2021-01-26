import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { debounce, pickBy, isEmpty, filter } from 'lodash';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import React, { useState } from 'react';
import connect from 'react-redux/es/connect/connect';

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
  setNotes
} from '../actions/dailyDocketActions';
import Alert from '../../components/Alert';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import Checkbox from '../../components/Checkbox';
import DateSelector from '../../components/DateSelector';
import Modal from '../../components/Modal';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import HEARING_REQUEST_TYPES from '../../../constants/HEARING_REQUEST_TYPES';

const notesFieldStyling = css({
  height: '100px',
  fontSize: '10pt'
});

const spanStyling = css({
  marginBotton: '5px'
});

const roomRequiredStyling = css({
  marginTop: '15px'
});

const statusMsgTitleStyle = css({
  fontSize: '18pt',
  textAlign: 'left'
});
const statusMsgDetailStyle = css({
  fontSize: '12pt',
  textAlign: 'left',
  margin: 0,
  color: '#e31c3d'
});

const titleStyling = css({
  marginBottom: 0,
  padding: 0
});

const requestTypeOptions = [
  { label: 'Video',
    value: HEARING_REQUEST_TYPES.video },
  { label: 'Central',
    value: HEARING_REQUEST_TYPES.central },
  { label: 'Virtual',
    value: HEARING_REQUEST_TYPES.virtual }
];

export const HearingDayAddModal = ({
  requestType, selectedHearingDay, vlj, coordinator, notes, roomRequired, selectedRegionalOffice,
  hearingSchedule, closeModal, cancelModal, user, ...props
}) => {
  const [selectedRequestType, setSelectedRequestType] = useState(null);
  const [serverError, setServerError] = useState(false);
  const [noRoomsAvailableError, setNoRoomsAvailableError] = useState(false);
  const [errorMessages, setErrorMessages] = useState({});

  const selectedVirtual = selectedRequestType === HEARING_REQUEST_TYPES.virtual;
  const selectedVideo = selectedRequestType === HEARING_REQUEST_TYPES.video;

  const dateError = errorMessages?.noDate || errorMessages?.invalidDate;

  const submitHearingDay = () => {
    const data = {
      request_type: requestType.value,
      scheduled_for: selectedHearingDay,
      judge_id: vlj.value,
      bva_poc: coordinator.value,
      notes,
      assign_room: selectedVirtual ? false : roomRequired,
      ...(selectedRegionalOffice?.key !== '' && requestType?.value !== 'C' &&
        { regional_office: selectedRegionalOffice?.key })
    };

    ApiUtil.post('/hearings/hearing_day.json', { data }).
      then((response) => {
        const resp = ApiUtil.convertToCamelCase(response?.body);

        const newHearings = Object.assign({}, hearingSchedule);
        const hearingsLength = Object.keys(newHearings).length;

        newHearings[hearingsLength] = resp?.hearing;

        props.onReceiveHearingSchedule(newHearings);
        closeModal();

      }, (error) => {
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
      setErrorMessages(errorMsgs);

      return;
    }

    submitHearingDay();
  };

  const onClickCancel = () => cancelModal();

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
    <Modal
      title="Add Hearing Day"
      closeHandler={onClickCancel}
      confirmButton={<Button classNames={['usa-button-secondary']} onClick={onClickConfirm}>Confirm </Button>}
      cancelButton={<Button linkStyling onClick={onClickCancel}>Go back</Button>}
    >
      <React.Fragment>
        <div {...fullWidth} {...css({ marginBottom: '0' })} >
          {!showAlert && <React.Fragment>
            <p {...spanStyling} >Please select the details of the new hearing day </p>
            <b {...titleStyling} >Select Hearing Date</b>
          </React.Fragment>}
          {showAlert &&
            <Alert type="error"
              title={alertTitle}
              scrollOnAlert={false}>
              {alertMessage}
            </Alert>}
          <DateSelector
            name="hearingDate"
            label={false}
            errorMessage={dateError ? getErrorMessage() : null}
            value={selectedHearingDay}
            onChange={onHearingDateChange}
            type="date"
          />
          <SearchableDropdown
            name="requestType"
            label="Select Hearing Type"
            strongLabel
            errorMessage={!dateError && errorMessages?.requestType ? getErrorMessage() : null}
            value={requestType}
            onChange={onRequestTypeChange}
            options={filteredRequestTypeOptions(requestTypeOptions)} />
          {(selectedVideo || selectedVirtual) &&
          <RegionalOfficeDropdown
            label="Select Regional Office (RO)"
            excludeVirtualHearingsOption={!selectedVirtual}
            errorMessage={errorMessages?.ro ? getErrorMessage(true) : null}
            onChange={onRoChange}
            readOnly={Boolean(selectedVirtual)}
            value={selectedVirtual ? 'R' : selectedRegionalOffice?.key} />
          }
          {selectedRequestType !== null &&
          <React.Fragment>
            <JudgeDropdown
              name="vlj"
              label="Select VLJ (Optional)"
              value={vlj?.value}
              onChange={(value, label) => props.selectVlj({ value, label })} />
            <HearingCoordinatorDropdown
              name="coordinator"
              label="Select Hearing Coordinator (Optional)"
              value={coordinator?.value}
              onChange={(value, label) => props.selectHearingCoordinator({ value, label })} />
          </React.Fragment>
          }
          <TextareaField
            name="Notes (Optional)"
            strongLabel
            onChange={(value) => props.setNotes(value)}
            textAreaStyling={notesFieldStyling}
            value={notes} />
          <Checkbox
            name="roomRequired"
            label="Assign Board Hearing Room"
            disabled={selectedVirtual}
            strongLabel
            value={selectedVirtual ? false : roomRequired}
            onChange={(value) => props.onAssignHearingRoom(value)}
            {...roomRequiredStyling} />
        </div>
      </React.Fragment>
    </Modal>
  );
};

HearingDayAddModal.propTypes = {
  cancelModal: PropTypes.func,
  closeModal: PropTypes.func,
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
  onSelectedHearingDayChange,
  onRegionalOfficeChange,
  selectRequestType,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onAssignHearingRoom,
  onReceiveHearingSchedule
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HearingDayAddModal));
