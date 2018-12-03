import React from 'react';
import { withRouter } from "react-router-dom";
import connect from 'react-redux/es/connect/connect';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import COPY from '../../../COPY.json';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import {fullWidth} from "../../queue/constants";
import SearchableDropdown from '../../components/SearchableDropdown'
import Checkbox from '../../components/Checkbox'
import TextareaField from '../../components/TextareaField';
import {bindActionCreators} from "redux";
import {selectHearingCoordinator, selectVlj, selectHearingRoom, setNotes} from "../actions";

const notesFieldStyling = css({
  height: '100px',
  fontSize: '10pt'
});

const roomOptions = [
    {label: "", value: ""},
    {label: "1W.0002", value: "1"},
    {label: "1W.0003", value: "2"}
  ];

// Next two options to be replaced by redux state once we determine
// the proper queries to identify these two sets of users.
const vljOptions = [
  {label: "", value: ""},
  {label: "Anjali Q. Abshire", value: "BVAAABSHIRE"},
  {label: "Jaida Y Wehner", value: "BVAJWEHNER"},
  {label: "Obie F Franecki", value: "BVAOFRANECKI"}
];

const coordinatorOptions = [
  {label: "", value: ""},
  {label: "Thomas A Warner", value: "BVATWARNER"},
  {label: "Mackenzie M Gerhold", value: "BVAMGERHOLD"}
];

const titleStyling = css({
  marginBottom: 0,
  padding: 0
});

const centralOfficeStaticEntry = [{
  label: 'Central',
  value: 'C'
}];

class HearingDayEditModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      modifyRoom: false,
      modifyVlj: false,
      modifyCoordinator: false,
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
    console.log("state at confirm is: ", this.state);
    this.props.closeModal();
  };

  modalCancelButton = () => {
    return <Button linkStyling onClick={this.onCancelModal}>Go back</Button>;
  };

  onCancelModal = () => {
    this.props.cancelModal();
  };

  onModifyRoom = () => {
    this.setState({modifyRoom: !this.state.modifyRoom});
  };

  onModifyVlj = () => {
    this.setState({modifyVlj: !this.state.modifyVlj});
  };

  onModifyCoordinator = () => {
    this.setState({modifyCoordinator: !this.state.modifyCoordinator});
  };

  onRoomChange = (value) => {
    this.props.selectHearingRoom(value);
  };

  onVljChange = (value) => {
    this.props.selectVlj(value);
  };

  onCoordinatorChange = (value) => {
    this.props.selectHearingCoordinator(value);
  };

  onNotesChange = (value) => {
    this.props.setNotes(value);
  }

  modalMessage = () => {
    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <Checkbox
          name="roomEdit"
          label="Change Room"
          strongLabel={true}
          value={this.state.modifyRoom}
          onChange={this.onModifyRoom} />
        <Checkbox
          name="vljEdit"
          label="Change VLJ"
          strongLabel={true}
          value={this.state.modifyVlj}
          onChange={this.onModifyVlj} />
        <Checkbox
          name="coordinatorEdit"
          label="Change Coordinator"
          strongLabel={true}
          value={this.state.modifyCoordinator}
          onChange={this.onModifyCoordinator} />
        <SearchableDropdown
          name="room"
          label="Select Room"
          strongLabel={true}
          readOnly={!this.state.modifyRoom}
          value={this.props.hearingRoom}
          onChange={this.onRoomChange}
          options={roomOptions}
          placeholder="Select..." />
        <SearchableDropdown
          name="vlj"
          label="Select VLJ"
          strongLabel={true}
          readOnly={!this.state.modifyVlj}
          value={this.props.vlj}
          onChange={this.onVljChange}
          options={vljOptions}
          placeholder="Select..."/>
        <SearchableDropdown
          name="coordinator"
          label="Select Hearing Coordinator"
          strongLabel={true}
          readOnly={!this.state.modifyCoordinator}
          value={this.props.coordinator}
          onChange={this.onCoordinatorChange}
          options={coordinatorOptions}
          placeholder="Select..."/>
        <TextareaField
          name="Notes"
          strongLabel={true}
          onChange={this.onNotesChange}
          textAreaStyling={notesFieldStyling}
          value={this.props.notes} />
      </div>
    </React.Fragment>
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
  vlj: state.hearingSchedule.vlj,
  coordinator: state.hearingSchedule.coordinator,
  notes: state.hearingSchedule.notes
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  selectVlj,
  selectHearingCoordinator,
  selectHearingRoom,
  setNotes,
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HearingDayEditModal));