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

const notesFieldStyling = css({
  height: '100px',
  fontSize: '10pt'
});

// May explore building API to get from back-end at future point.
const roomOptions = [
  { label: '',
    value: '' },
  { label: '1W200A',
    value: '1' },
  { label: '1W200B',
    value: '2' },
  { label: '1200C',
    value: '3' },
  { label: '1W424',
    value: '4' },
  { label: '1W428',
    value: '5' },
  { label: '1W432',
    value: '6' },
  { label: '1W434',
    value: '7' },
  { label: '1W435',
    value: '8' },
  { label: '1W436',
    value: '9' },
  { label: '1W437',
    value: '10' },
  { label: '1W438',
    value: '11' },
  { label: '1W439',
    value: '12' },
  { label: '1W440',
    value: '13' }
];

class HearingDayEditModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      modifyRoom: false,
      modifyVlj: false,
      modifyCoordinator: false
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
    this.props.closeModal();
  };

  modalCancelButton = () => {
    return <Button linkStyling onClick={this.onCancelModal}>Go back</Button>;
  };

  onCancelModal = () => {
    this.props.cancelModal();
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
          label="Change Room"
          strongLabel
          value={this.state.modifyRoom}
          onChange={this.onModifyRoom} />
        <Checkbox
          name="vljEdit"
          label="Change VLJ"
          strongLabel
          value={this.state.modifyVlj}
          onChange={this.onModifyVlj} />
        <Checkbox
          name="coordinatorEdit"
          label="Change Coordinator"
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
          options={roomOptions}
          placeholder="Select..." />
        <SearchableDropdown
          name="vlj"
          label="Select VLJ"
          strongLabel
          readOnly={!this.state.modifyVlj}
          value={this.props.vlj}
          onChange={this.onVljChange}
          options={this.props.activeJudges}
          placeholder="Select..." />
        <SearchableDropdown
          name="coordinator"
          label="Select Hearing Coordinator"
          strongLabel
          readOnly={!this.state.modifyCoordinator}
          value={this.props.coordinator}
          onChange={this.onCoordinatorChange}
          options={this.props.activeCoordinators}
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

HearingDayEditModal.propTypes = {
  userId: PropTypes.number,
  userCssId: PropTypes.string,
  closeModal: PropTypes.func,
  cancelModal: PropTypes.func
};

const mapStateToProps = (state) => ({
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
