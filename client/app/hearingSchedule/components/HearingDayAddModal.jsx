import React from 'react';
import { withRouter } from 'react-router-dom';
import connect from 'react-redux/es/connect/connect';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import { fullWidth } from '../../queue/constants';
import RoSelectorDropdown from '../../components/RoSelectorDropdown';
import DateSelector from '../../components/DateSelector';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import { bindActionCreators } from 'redux';
import {
  onSelectedHearingDayChange,
  selectRequestType,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onAssignHearingRoom,
  onReceiveHearingSchedule
} from '../actions';
import { onRegionalOfficeChange } from '../../components/common/actions';
import Checkbox from '../../components/Checkbox';
import Alert from '../../components/Alert';
import ApiUtil from '../../util/ApiUtil';
import { formatDateStr } from '../../util/DateUtil';

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

const centralOfficeStaticEntry = [{
  label: 'Central',
  value: 'C'
}];

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
      noRoomsAvailable: false
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
      noRoomsAvailable: false });

    if (this.props.selectedHearingDay === '') {
      this.setState({ dateError: true });
      errorMessages.push('Please make sure you have entered a Hearing Date');
    }

    if (this.props.requestType === '') {
      this.setState({ typeError: true });
      errorMessages.push('Please make sure you have entered a Hearing Type');
    }

    if (this.state.videoSelected && !this.props.selectedRegionalOffice) {
      this.setState({ roError: true });
      roErrorMessages.push('Please make sure you select a Regional Office');
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

  persistHearingDay = () => {
    let data = {
      request_type: this.props.requestType.value,
      scheduled_for: this.props.selectedHearingDay,
      judge_id: this.props.vlj.value,
      bva_poc: this.props.coordinator.label,
      notes: this.props.notes,
      assign_room: this.props.roomRequired
    };

    if (this.props.selectedRegionalOffice &&
      this.props.selectedRegionalOffice.value !== '' &&
      this.props.requestType.value !== 'C') {
      data.regional_office = this.props.selectedRegionalOffice.value;
    }

    ApiUtil.post('/hearings/hearing_day.json', { data }).
      then((response) => {
        const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

        const newHearings = Object.assign({}, this.props.hearingSchedule);
        const hearingsLength = Object.keys(newHearings).length;

        newHearings[hearingsLength] = resp.hearing;

        this.props.onReceiveHearingSchedule(newHearings);
        this.props.closeModal();

      }, (error) => {
        if (error.response.body && error.response.body.errors &&
        error.response.body.errors[0].title === 'No rooms available') {
          this.setState({ noRoomsAvailable: true });
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

    switch (value.value) {
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

  resetErrorState = () => {
    this.setState({ dateError: false,
      typeError: false,
      roError: false });
  };

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
    return this.state.serverError ? 'An Error Occurred' :
      `No Rooms Available for Hearing Day ${formatDateStr(this.props.selectedHearingDay)}`;
  };

  getAlertMessage = () => {
    return this.state.serverError ? 'You are unable to complete this action.' :
      'All hearing rooms are taken for the date you selected.';
  };

  showAlert = () => {
    return this.state.serverError || this.state.noRoomsAvailable;
  }

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
        <RoSelectorDropdown
          label="Select Regional Office (RO)"
          strongLabel
          errorMessage={this.state.roError ? this.getRoErrorMessages() : null}
          onChange={this.onRegionalOfficeChange}
          value={this.props.selectedRegionalOffice}
          staticOptions={centralOfficeStaticEntry} />
        }
        {(this.state.videoSelected || this.state.centralOfficeSelected) &&
        <React.Fragment>
          <SearchableDropdown
            name="vlj"
            label="Select VLJ (Optional)"
            strongLabel
            value={this.props.vlj}
            onChange={this.onVljChange}
            options={this.props.activeJudges} />
          <SearchableDropdown
            name="coordinator"
            label="Select Hearing Coordinator (Optional)"
            strongLabel
            value={this.props.coordinator}
            onChange={this.onCoordinatorChange}
            options={this.props.activeCoordinators} />
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

    return <AppSegment filledBackground>
      <div className="cf-modal-scroll">
        <Modal
          title="Add Hearing Day"
          closeHandler={this.onCancelModal}
          confirmButton={this.modalConfirmButton()}
          cancelButton={this.modalCancelButton()}
        >
          {this.modalMessage()}
        </Modal>
      </div>
    </AppSegment>;
  }
}

HearingDayAddModal.propTypes = {
  userId: PropTypes.number,
  userCssId: PropTypes.string,
  closeModal: PropTypes.func,
  cancelModal: PropTypes.func
};

const mapStateToProps = (state) => ({
  hearingSchedule: state.hearingSchedule.hearingSchedule,
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  regionalOffices: state.components.regionalOffices,
  selectedHearingDay: state.hearingSchedule.selectedHearingDay,
  requestType: state.hearingSchedule.requestType,
  vlj: state.hearingSchedule.vlj,
  coordinator: state.hearingSchedule.coordinator,
  notes: state.hearingSchedule.notes,
  roomRequired: state.hearingSchedule.roomRequired,
  activeJudges: state.hearingSchedule.activeJudges,
  activeCoordinators: state.hearingSchedule.activeCoordinators
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
