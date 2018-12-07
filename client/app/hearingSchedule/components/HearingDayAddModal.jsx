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
import { onSelectedHearingDayChange,
  selectHearingType,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onAssignHearingRoom
} from '../actions';
import { onRegionalOfficeChange } from '../../components/common/actions';
import Checkbox from '../../components/Checkbox';

const notesFieldStyling = css({
  height: '100px',
  fontSize: '10pt'
});

const spanStyling = css({
  marginBotton: '5px'
});

const roomNotRequiredStyling = css({
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

const hearingTypeOptions = [
  { label: '',
    value: '' },
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
      roErrorMessages: []
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

    if (this.props.selectedHearingDay === '') {
      this.setState({ dateError: true });
      errorMessages.push('Please make sure you have entered a Hearing Date');
    }

    if (this.props.hearingType === '') {
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

    this.props.closeModal();
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

  onHearingTypeChange = (value) => {
    this.props.selectHearingType(value);
    this.resetErrorState();

    switch (value.value) {
    case 'V':
      this.setState({ videoSelected: true });
      this.setState({ centralOfficeSelected: false });
      break;
    case 'C':
      this.setState({ videoSelected: false });
      this.setState({ centralOfficeSelected: true });
      break;
    default:
      this.setState({ videoSelected: false });
      this.setState({ centralOfficeSelected: false });
    }
  };

  onRegionalOfficeChange = (option) => {
    this.props.onRegionalOfficeChange(option);
    this.resetErrorState();
  };

  resetErrorState = () => {
    this.setState({ dateError: false });
    this.setState({ typeError: false });
    this.setState({ roError: false });
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

  onRoomNotRequired = (value) => {
    this.props.onAssignHearingRoom(value);
  };

  modalMessage = () => {
    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <p {...spanStyling} >Please select the details of the new hearing day </p>
        <b {...titleStyling} >Select Hearing Date</b>
        <DateSelector
          name="hearingDate"
          label={false}
          errorMessage={((this.state.dateError && this.state.typeError) || (this.state.dateError)) ?
            this.getDateTypeErrorMessages() : null}
          value={this.props.selectedHearingDay}
          onChange={this.onHearingDateChange}
          type="date"
        />
        <SearchableDropdown
          name="hearingType"
          label="Select Hearing Type"
          strongLabel
          errorMessage={(!this.state.dateError && this.state.typeError) ? this.getDateTypeErrorMessages() : null}
          value={this.props.hearingType}
          onChange={this.onHearingTypeChange}
          options={hearingTypeOptions} />
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
        <SearchableDropdown
          name="vlj"
          label="Select VLJ (Optional)"
          strongLabel
          value={this.props.vlj}
          onChange={this.onVljChange}
          options={this.props.activeJudges} />
        }
        {(this.state.videoSelected || this.state.centralOfficeSelected) &&
        <SearchableDropdown
          name="coordinator"
          label="Select Hearing Coordinator (Optional)"
          strongLabel
          value={this.props.coordinator}
          onChange={this.onCoordinatorChange}
          options={this.props.activeCoordinators} />
        }
        <TextareaField
          name="Notes (Optional)"
          strongLabel
          onChange={this.onNotesChange}
          textAreaStyling={notesFieldStyling}
          value={this.props.notes} />
        <Checkbox
          name="roomNotRequired"
          label="Board Hearing Room Not Required"
          strongLabel
          value={this.props.roomNotRequired}
          onChange={this.onRoomNotRequired}
          {...roomNotRequiredStyling} />
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
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  regionalOffices: state.components.regionalOffices,
  selectedHearingDay: state.hearingSchedule.selectedHearingDay,
  hearingType: state.hearingSchedule.hearingType,
  vlj: state.hearingSchedule.vlj,
  coordinator: state.hearingSchedule.coordinator,
  notes: state.hearingSchedule.notes,
  roomNotRequired: state.hearingSchedule.roomNotRequired,
  activeJudges: state.hearingSchedule.activeJudges,
  activeCoordinators: state.hearingSchedule.activeCoordinators
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onSelectedHearingDayChange,
  onRegionalOfficeChange,
  selectHearingType,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onAssignHearingRoom
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HearingDayAddModal));
