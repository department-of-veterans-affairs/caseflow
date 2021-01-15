import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { debounce } from 'lodash';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import React from 'react';
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

const requestTypeOptions = [
  { label: 'Video',
    value: 'V' },
  { label: 'Central',
    value: 'C' }
];

const titleStyling = css({
  marginBottom: 0,
  padding: 0
});

class HearingDayAddModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      videoSelected: false,
      centralOfficeSelected: false,
      dateError: false,
      typeError: false,
      roError: false,
      errorMessages: [],
      roErrorMessages: [],
      serverError: false,
      noRoomsAvailableError: false
    };
  }

  modalConfirmButton = () => {
    return <Button
      classNames={['usa-button-secondary']}
      onClick={this.onClickConfirm}
    >Confirm
    </Button>;
  };

  onClickConfirm = () => {
    let errorMessages = [];
    let roErrorMessages = [];

    this.setState({ serverError: false,
      noRoomsAvailableError: false });

    if (this.props.selectedHearingDay === '') {
      this.setState({ dateError: true });
      errorMessages.push('Please make sure you have entered a Hearing Date');
    }

    if (this.props.requestType === '') {
      this.setState({ typeError: true });
      errorMessages.push('Please make sure you have entered a Hearing Type');
    }

    if (this.state.videoSelected && !this.props.selectedRegionalOffice.key) {
      this.setState({ roError: true });
      roErrorMessages.push('Please make sure you select a Regional Office');
    }

    if (this.state.videoSelected && this.videoHearingDateNotValid(this.props.selectedHearingDay)) {
      this.setState({ dateError: true });
      errorMessages.push('Video hearing days cannot be scheduled for prior than April 1st through Caseflow.');
    }

    if (errorMessages.length > 0) {
      this.setState({ errorMessages });
    }

    if (roErrorMessages.length > 0) {
      this.setState({ roErrorMessages });
    }

    if (errorMessages.length > 0 || roErrorMessages.length > 0) {
      return;
    }

    this.persistHearingDay();
  };

  videoHearingDateNotValid = (hearingDate) => {
    const integerDate = parseInt(hearingDate.split('-').join(''), 10);

    return integerDate < 20190401;
  };

  persistHearingDay = () => {
    let data = {
      request_type: this.props.requestType.value,
      scheduled_for: this.props.selectedHearingDay,
      judge_id: this.props.vlj.value,
      bva_poc: this.props.coordinator.value,
      notes: this.props.notes,
      assign_room: this.props.roomRequired
    };

    if (this.props.selectedRegionalOffice?.key !== '' &&
      this.props.requestType.value !== 'C') {
      data.regional_office = this.props.selectedRegionalOffice.key;
    }

    ApiUtil.post('/hearings/hearing_day.json', { data }).
      then((response) => {
        const resp = ApiUtil.convertToCamelCase(response.body);

        const newHearings = Object.assign({}, this.props.hearingSchedule);
        const hearingsLength = Object.keys(newHearings).length;

        newHearings[hearingsLength] = resp.hearing;

        this.props.onReceiveHearingSchedule(newHearings);
        this.props.closeModal();

      }, (error) => {
        if (error.response.body && error.response.body.errors &&
        error.response.body.errors[0].status === 400) {
          this.setState({ noRoomsAvailableError: error.response.body.errors[0] });
        } else {
        // All other server errors
          this.setState({ serverError: true });
        }
      });
  };

  getDateTypeErrorMessages = () => {
    return <div>
      <span {...statusMsgTitleStyle}>Cannot create a New Hearing Day</span>
      <ul {...statusMsgDetailStyle} >
        {
          this.state.errorMessages.map((item, i) => <li key={i}>{item}</li>)
        }
      </ul></div>;
  };

  getRoErrorMessages = () => {
    return <div>
      <span {...statusMsgTitleStyle}>Hearing type is a Video hearing</span>
      <ul {...statusMsgDetailStyle} >
        {
          this.state.roErrorMessages.map((item, i) => <li key={i}>{item}</li>)
        }
      </ul></div>;
  };

  modalCancelButton = () => {
    return <Button linkStyling onClick={this.onCancelModal}>Go back</Button>;
  };

  onCancelModal = () => {
    this.props.cancelModal();
  };

  onHearingDateChange = (option) => {
    this.props.onSelectedHearingDayChange(option);
    this.resetErrorState();
  };

  onRequestTypeChange = (value) => {
    this.props.selectRequestType(value);
    this.resetErrorState();

    switch ((value || {}).value) {
    case 'V':
      this.setState({ videoSelected: true,
        centralOfficeSelected: false });
      break;
    case 'C':
      this.setState({ videoSelected: false,
        centralOfficeSelected: true });
      break;
    default:
      this.setState({ videoSelected: false,
        centralOfficeSelected: false });
    }
  };

  onRegionalOfficeChange = (option) => {
    this.props.onRegionalOfficeChange(option);
    this.resetErrorState();
  };

  resetErrorState = debounce(() => {
    this.setState({ dateError: false,
      typeError: false,
      roError: false });
  }, 250);

  onVljChange = (value) => {
    this.props.selectVlj(value);
  };

  onCoordinatorChange = (value) => {
    this.props.selectHearingCoordinator(value);
  };

  onNotesChange = (value) => {
    this.props.setNotes(value);
  };

  onRoomRequired = (value) => {
    this.props.onAssignHearingRoom(value);
  };

  getAlertTitle = () => {
    return this.state.noRoomsAvailableError ? this.state.noRoomsAvailableError.title :
      'An error has occurred';
  };

  getAlertMessage = () => {
    return this.state.noRoomsAvailableError ? this.state.noRoomsAvailableError.detail :
      'You are unable to complete this action.';
  };

  showAlert = () => {
    return this.state.serverError || this.state.noRoomsAvailableError;
  };

  modalMessage = () => {
    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        {!this.showAlert() && <React.Fragment>
          <p {...spanStyling} >Please select the details of the new hearing day </p>
          <b {...titleStyling} >Select Hearing Date</b>
        </React.Fragment>}
        {this.showAlert() &&
          <Alert type="error"
            title={this.getAlertTitle()}
            scrollOnAlert={false}>
            {this.getAlertMessage()}
          </Alert>}
        <DateSelector
          name="hearingDate"
          label={false}
          errorMessage={this.state.dateError ?
            this.getDateTypeErrorMessages() : null}
          value={this.props.selectedHearingDay}
          onChange={this.onHearingDateChange}
          type="date"
        />
        <SearchableDropdown
          name="requestType"
          label="Select Hearing Type"
          strongLabel
          errorMessage={(!this.state.dateError && this.state.typeError) ? this.getDateTypeErrorMessages() : null}
          value={this.props.requestType}
          onChange={this.onRequestTypeChange}
          options={requestTypeOptions} />
        {this.state.videoSelected &&
        <RegionalOfficeDropdown
          label="Select Regional Office (RO)"
          excludeVirtualHearingsOption
          errorMessage={this.state.roError ? this.getRoErrorMessages() : null}
          onChange={this.onRegionalOfficeChange}
          value={this.props.selectedRegionalOffice?.key} />
        }
        {(this.state.videoSelected || this.state.centralOfficeSelected) &&
        <React.Fragment>
          <JudgeDropdown
            name="vlj"
            label="Select VLJ (Optional)"
            value={this.props.vlj.value}
            onChange={(value, label) => this.onVljChange({
              value,
              label
            })} />
          <HearingCoordinatorDropdown
            name="coordinator"
            label="Select Hearing Coordinator (Optional)"
            value={this.props.coordinator.value}
            onChange={(value, label) => this.onCoordinatorChange({
              value,
              label
            })} />
        </React.Fragment>
        }
        <TextareaField
          name="Notes (Optional)"
          strongLabel
          onChange={this.onNotesChange}
          textAreaStyling={notesFieldStyling}
          value={this.props.notes} />
        <Checkbox
          name="roomRequired"
          label="Assign Board Hearing Room"
          strongLabel
          value={this.props.roomRequired}
          onChange={this.onRoomRequired}
          {...roomRequiredStyling} />
      </div>
    </React.Fragment>;
  };

  render() {
    return (
      <Modal
        title="Add Hearing Day"
        closeHandler={this.onCancelModal}
        confirmButton={this.modalConfirmButton()}
        cancelButton={this.modalCancelButton()}
      >
        {this.modalMessage()}
      </Modal>
    );
  }
}

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
  regionalOffices: PropTypes.shape({
    options: PropTypes.arrayOf(PropTypes.object)
  }),
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
  userCssId: PropTypes.string,
  userId: PropTypes.number,
  vlj: PropTypes.shape({
    value: PropTypes.string
  })
};

const mapStateToProps = (state) => ({
  hearingSchedule: state.hearingSchedule.hearingSchedule,
  selectedRegionalOffice: state.components.selectedRegionalOffice || {},
  regionalOffices: state.components.regionalOffices,
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
