import React from 'react';
import { withRouter } from 'react-router-dom';
import connect from 'react-redux/es/connect/connect';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import { fullWidth } from '../../queue/constants';
import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';
import { bindActionCreators } from 'redux';
import { selectHearingCoordinator,
  selectVlj,
  selectHearingRoom,
  setNotes,
  onHearingDayModified
} from '../actions';
import HEARING_ROOMS_LIST from '../../../constants/HEARING_ROOMS_LIST.json';

const notesFieldStyling = css({
  height: '100px',
  fontSize: '10pt'
});

class HearingDayEditModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      modifyRoom: false,
      modifyVlj: false,
      modifyCoordinator: false
    };
  }

  componentWillMount = () => {
    // find labels in options before passing values to modal
    if (this.props.dailyDocket.roomInfo) {
      const roomInfo = this.props.dailyDocket.roomInfo.split(' ');

      this.props.selectHearingRoom(roomInfo[0]);
    }
  };

  formatRoomOptions = () => {
    const roomOptions = [];
    const rooms = Object.keys(HEARING_ROOMS_LIST);

    for (const roomKey of rooms) {
      const room = HEARING_ROOMS_LIST[roomKey];

      roomOptions.push({ label: room.label,
        value: roomKey });
    }

    return roomOptions;
  };

  modalConfirmButton = () => {
    return <Button
      classNames={['usa-button-secondary']}
      onClick={this.props.closeModal}
    >Confirm
    </Button>;
  };

  modalCancelButton = () => {
    return <Button linkStyling onClick={this.props.cancelModal}>Go back</Button>;
  };

  onModifyRoom = () => {
    this.setState({ modifyRoom: !this.state.modifyRoom });
  };

  onModifyVlj = () => {
    this.setState({ modifyVlj: !this.state.modifyVlj });
  };

  onModifyCoordinator = () => {
    this.setState({ modifyCoordinator: !this.state.modifyCoordinator });
  };

  onRoomChange = (value) => {
    this.props.selectHearingRoom(value);
    this.props.onHearingDayModified(true);
  };

  onVljChange = (value) => {
    this.props.selectVlj(value);
    this.props.onHearingDayModified(true);
  };

  onCoordinatorChange = (value) => {
    this.props.selectHearingCoordinator(value);
    this.props.onHearingDayModified(true);
  };

  onNotesChange = (value) => {
    this.props.setNotes(value);
    this.props.onHearingDayModified(true);
  }

  modalMessage = () => {
    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <Checkbox
          name="roomEdit"
          label={<strong>Change Room</strong>}
          strongLabel
          value={this.state.modifyRoom}
          onChange={this.onModifyRoom} />
        <Checkbox
          name="vljEdit"
          label={<strong>Change VLJ</strong>}
          strongLabel
          value={this.state.modifyVlj}
          onChange={this.onModifyVlj} />
        <Checkbox
          name="coordinatorEdit"
          label={<strong>Change Coordinator</strong>}
          strongLabel
          value={this.state.modifyCoordinator}
          onChange={this.onModifyCoordinator} />
        <SearchableDropdown
          name="room"
          label="Select Room"
          strongLabel
          readOnly={!this.state.modifyRoom}
          value={this.props.hearingRoom}
          onChange={this.onRoomChange}
          options={this.formatRoomOptions()}
          placeholder="Please Select..." />
        <SearchableDropdown
          name="vlj"
          label="Select VLJ"
          strongLabel
          readOnly={!this.state.modifyVlj}
          value={this.props.vlj}
          onChange={this.onVljChange}
          options={this.props.activeJudges}
          placeholder="Please Select..." />
        <SearchableDropdown
          name="coordinator"
          label="Select Hearing Coordinator"
          strongLabel
          readOnly={!this.state.modifyCoordinator}
          value={this.props.coordinator}
          onChange={this.onCoordinatorChange}
          options={this.props.activeCoordinators}
          placeholder="Please Select..." />
        <TextareaField
          name="Notes"
          strongLabel
          onChange={this.onNotesChange}
          textAreaStyling={notesFieldStyling}
          value={this.props.notes} />
      </div>
    </React.Fragment>;
  };

  render() {

    return <AppSegment filledBackground>
      <div className="cf-modal-scroll">
        <Modal
          title="Edit Hearing Day"
          closeHandler={this.props.cancelModal}
          confirmButton={this.modalConfirmButton()}
          cancelButton={this.modalCancelButton()}
        >
          {this.modalMessage()}
        </Modal>
      </div>
    </AppSegment>;
  }
}

HearingDayEditModal.propTypes = {
  userId: PropTypes.number,
  userCssId: PropTypes.string,
  closeModal: PropTypes.func,
  cancelModal: PropTypes.func
};

const mapStateToProps = (state) => ({
  dailyDocket: state.hearingSchedule.dailyDocket,
  hearingRoom: state.hearingSchedule.hearingRoom,
  vlj: state.hearingSchedule.vlj,
  coordinator: state.hearingSchedule.coordinator,
  notes: state.hearingSchedule.notes,
  activeJudges: state.hearingSchedule.activeJudges,
  activeCoordinators: state.hearingSchedule.activeCoordinators
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  selectVlj,
  selectHearingCoordinator,
  selectHearingRoom,
  setNotes,
  onHearingDayModified
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HearingDayEditModal));
