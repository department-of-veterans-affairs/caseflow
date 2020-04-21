import React from 'react';
import { withRouter } from 'react-router-dom';
import connect from 'react-redux/es/connect/connect';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import { fullWidth } from '../../queue/constants';
import { HearingRoomDropdown, JudgeDropdown, HearingCoordinatorDropdown } from '../../components/DataDropdowns';
import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';
import { bindActionCreators } from 'redux';
import {
  selectHearingCoordinator,
  selectVlj,
  selectHearingRoom,
  setNotes,
  onHearingDayModified
} from '../actions/dailyDocketActions';
import HEARING_ROOMS_LIST from '../../../constants/HEARING_ROOMS_LIST.json';
import _ from 'lodash';

const notesFieldStyling = css({
  height: '100px',
  fontSize: '10pt'
});

export const ModalWrapper = ({ children }) => (
  <AppSegment filledBackground>
    <div className="cf-modal-scroll">{children}</div>
  </AppSegment>
);

class HearingDayEditModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      modifyRoom: false,
      modifyVlj: false,
      modifyCoordinator: false
    };
  }

  componentDidMount = () => {
    // find labels in options before passing values to modal
    this.initialState();
    if (this.props.dailyDocket.roomInfo) {
      const roomInfo = this.props.dailyDocket.roomInfo.split(' ');

      this.props.selectHearingRoom(roomInfo[0]);
    }
  };

  componentDidUpdate(prevProps) {
    if (
      prevProps.activeJudges !== this.props.activeJudges ||
      prevProps.activeCoordinators !== this.props.activeCoordinators
    ) {
      this.initialState();
    }
  }

  modalConfirmButton = () => {
    return (
      <Button classNames={['usa-button-secondary']} onClick={this.props.closeModal}>
        Confirm
      </Button>
    );
  };

  modalCancelButton = () => {
    return (
      <Button linkStyling onClick={this.props.cancelModal}>
        Go back
      </Button>
    );
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
  };

  initialState = () => {
    // find labels in options before passing values to modal
    const room = _.findKey(HEARING_ROOMS_LIST, { label: this.props.dailyDocket.room }) || this.props.dailyDocket.room;

    if (room) {
      const roomOption = { label: HEARING_ROOMS_LIST[room.toString()].label, value: room.toString() };

      this.props.selectHearingRoom(roomOption);
    }

    const judge = _.find(this.props.activeJudges, { value: (this.props.dailyDocket.judgeId || '').toString() });
    const coordinator = _.find(this.props.activeCoordinators, { label: this.props.dailyDocket.bvaPoc });

    this.props.selectVlj(judge);
    this.props.selectHearingCoordinator(coordinator);
    this.props.setNotes(this.props.dailyDocket.notes);
    this.props.onHearingDayModified(false);
  };

  modalMessage = () => {
    return (
      <React.Fragment>
        <div {...fullWidth} {...css({ marginBottom: '0' })}>
          <Checkbox
            name="roomEdit"
            label={<strong>Change Room</strong>}
            strongLabel
            value={this.state.modifyRoom}
            onChange={this.onModifyRoom}
          />
          <Checkbox
            name="vljEdit"
            label={<strong>Change VLJ</strong>}
            strongLabel
            value={this.state.modifyVlj}
            onChange={this.onModifyVlj}
          />
          <Checkbox
            name="coordinatorEdit"
            label={<strong>Change Coordinator</strong>}
            strongLabel
            value={this.state.modifyCoordinator}
            onChange={this.onModifyCoordinator}
          />
          <HearingRoomDropdown
            name="room"
            label="Select Room"
            readOnly={!this.state.modifyRoom}
            value={this.props.hearingRoom ? this.props.hearingRoom.value : null}
            onChange={(value, label) =>
              this.onRoomChange({
                value,
                label
              })
            }
            placeholder="Select..."
          />
          <JudgeDropdown
            label="Select VLJ"
            readOnly={!this.state.modifyVlj}
            value={this.props.vlj.value}
            onChange={(value, label) =>
              this.onVljChange({
                value,
                label
              })
            }
            placeholder="Select..."
          />
          <HearingCoordinatorDropdown
            label="Select Hearing Coordinator"
            readOnly={!this.state.modifyCoordinator}
            value={this.props.coordinator.value}
            onChange={(value, label) =>
              this.onCoordinatorChange({
                value,
                label
              })
            }
            placeholder="Select..."
          />
          <TextareaField
            name="Notes"
            strongLabel
            onChange={this.onNotesChange}
            textAreaStyling={notesFieldStyling}
            value={this.props.notes}
          />
        </div>
      </React.Fragment>
    );
  };

  render() {
    return (
      <Modal
        Wrapper={ModalWrapper}
        show={this.props.show}
        title="Edit Hearing Day"
        closeHandler={this.props.cancelModal}
        confirmButton={this.modalConfirmButton()}
        cancelButton={this.modalCancelButton()}
      >
        {this.modalMessage()}
      </Modal>
    );
  }
}

HearingDayEditModal.propTypes = {
  userId: PropTypes.number,
  userCssId: PropTypes.string,
  closeModal: PropTypes.func,
  cancelModal: PropTypes.func
};

const mapStateToProps = (state) => ({
  dailyDocket: state.dailyDocket.hearingDay,
  hearingRoom: state.dailyDocket.hearingRoom || {},
  vlj: state.dailyDocket.vlj || {},
  coordinator: state.dailyDocket.coordinator || {},
  activeJudges: state.components.dropdowns.judges.options,
  activeCoordinators: state.components.dropdowns.hearingCoordinators.options,
  notes: state.dailyDocket.notes
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      selectVlj,
      selectHearingCoordinator,
      selectHearingRoom,
      setNotes,
      onHearingDayModified
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(HearingDayEditModal)
);
