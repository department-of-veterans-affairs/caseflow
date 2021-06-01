import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { withRouter } from 'react-router-dom';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import connect from 'react-redux/es/connect/connect';

import {
  HearingRoomDropdown,
  JudgeDropdown,
  HearingCoordinatorDropdown
} from '../../components/DataDropdowns';
import { fullWidth } from '../../queue/constants';
import { selectHearingCoordinator,
  selectVlj,
  selectHearingRoom,
  setNotes,
  onHearingDayModified
} from '../actions/dailyDocketActions';
import Button from '../../components/Button';
import Checkbox from '../../components/Checkbox';
import HEARING_ROOMS_LIST from '../../../constants/HEARING_ROOMS_LIST';
import Modal from '../../components/Modal';
import TextareaField from '../../components/TextareaField';
import HEARING_REQUEST_TYPES from '../../../constants/HEARING_REQUEST_TYPES';

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

  componentDidMount = () => {
    // find labels in options before passing values to modal
    this.initialState();
  };

  componentDidUpdate(prevProps) {
    if (prevProps.activeJudges !== this.props.activeJudges ||
        prevProps.activeCoordinators !== this.props.activeCoordinators) {
      this.initialState();
    }
  }

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

  initialState = () => {
    // find labels in options before passing values to modal
    const room = _.findKey(HEARING_ROOMS_LIST, { label: this.props.dailyDocket.room }) || this.props.dailyDocket.room;

    if (room) {
      const roomOption = { label: HEARING_ROOMS_LIST[room.toString()].label,
        value: room.toString() };

      this.props.selectHearingRoom(roomOption);
    }

    const judge = _.find(this.props.activeJudges, { value: (this.props.dailyDocket.judgeId || '').toString() });
    const coordinator = _.find(this.props.activeCoordinators, { label: this.props.dailyDocket.bvaPoc });

    this.props.selectVlj(judge);
    this.props.selectHearingCoordinator(coordinator);
    this.props.setNotes(this.props.dailyDocket.notes);
    this.props.onHearingDayModified(false);
  }

  modalMessage = () => {
    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <Checkbox
          name="roomEdit"
          label={<strong>Change Room</strong>}
          strongLabel
          disabled={this.props.requestType === HEARING_REQUEST_TYPES.virtual}
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
        <HearingRoomDropdown
          name="room"
          label="Select Room"
          readOnly={!this.state.modifyRoom}
          value={this.props.hearingRoom ? this.props.hearingRoom.value : null}
          onChange={(value, label) => this.onRoomChange({
            value,
            label
          })}
          placeholder="Select..." />
        <JudgeDropdown
          label="Select VLJ"
          readOnly={!this.state.modifyVlj}
          value={this.props.vlj.value}
          onChange={(value, label) => this.onVljChange({
            value,
            label
          })}
          placeholder="Select..." />
        <HearingCoordinatorDropdown
          label="Select Hearing Coordinator"
          readOnly={!this.state.modifyCoordinator}
          value={this.props.coordinator.value}
          onChange={(value, label) => this.onCoordinatorChange({
            value,
            label
          })}
          placeholder="Select..." />
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
  activeJudges: PropTypes.arrayOf(
    PropTypes.shape({
      value: PropTypes.any,
      label: PropTypes.string,
    })
  ),
  activeCoordinators: PropTypes.arrayOf(
    PropTypes.shape({
      value: PropTypes.any,
      label: PropTypes.string,
    })
  ),
  coordinator: PropTypes.shape({
    value: PropTypes.string
  }),
  vlj: PropTypes.shape({
    value: PropTypes.string
  }),
  dailyDocket: PropTypes.shape({
    bvaPoc: PropTypes.string,
    judgeId: PropTypes.number,
    notes: PropTypes.string,
    room: PropTypes.string
  }),
  hearingRoom: PropTypes.shape({
    value: PropTypes.string
  }),
  notes: PropTypes.string,
  userId: PropTypes.number,
  userCssId: PropTypes.string,
  closeModal: PropTypes.func,
  cancelModal: PropTypes.func,
  onHearingDayModified: PropTypes.func,
  selectHearingCoordinator: PropTypes.func,
  selectHearingRoom: PropTypes.func,
  setNotes: PropTypes.func,
  selectVlj: PropTypes.func,
  requestType: PropTypes.string
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

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onHearingDayModified,
  selectHearingCoordinator,
  selectHearingRoom,
  selectVlj,
  setNotes
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HearingDayEditModal));
