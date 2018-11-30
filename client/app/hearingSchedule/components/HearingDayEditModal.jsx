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
import Dropdown from '../../components/Dropdown'
import Checkbox from '../../components/Checkbox'
import TextareaField from '../../components/TextareaField';
import {bindActionCreators} from "redux";
import { onSelectedHearingDayChange } from "../actions";
import { onRegionalOfficeChange } from '../../components/common/actions'

const notesFieldStyling = css({
  height: '100px',
  fontSize: '10pt'
});

const roomOptions = [
    {displayText: "", value: ""},
    {displayText: "1W.0002", value: "1"},
    {displayText: "1W.0003", value: "2"}
  ];

// Next two options to be replaced by redux state once we determine
// the proper queries to identify these two sets of users.
const vljOptions = [
  {displayText: "", value: ""},
  {displayText: "Anjali Q. Abshire", value: "BVAAABSHIRE"},
  {displayText: "Jaida Y Wehner", value: "BVAJWEHNER"},
  {displayText: "Obie F Franecki", value: "BVAOFRANECKI"}
];

const coordinatorOptions = [
  {displayText: "", value: ""},
  {displayText: "Thomas A Warner", value: "BVATWARNER"},
  {displayText: "Mackenzie M Gerhold", value: "BVAMGERHOLD"}
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
      selectedRoom: '',
      selectedVLJ: '',
      selectedCoordinator: '',
      notes: ''
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
    //validation
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
    this.setState({selectedRoom: value});
  };

  onVljChange = (value) => {
    this.setState({selectedVlj: value});
  };

  onCoordinatorChange = (value) => {
    this.setState({selectedCoordinator: value});
  };

  onNotesChange = (value) => {
    this.setState({notes: value})
  }

  modalMessage = () => {
    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <Checkbox
          name="roomEdit"
          label="Change Room"
          strongLabel={true}
          checked={this.state.modifyRoom}
          onChange={this.onModifyRoom} />
        <Checkbox
          name="vljEdit"
          label="Change VLJ"
          strongLabel={true}
          checked={this.state.modifyVlj}
          onChange={this.onModifyVlj} />
        <Checkbox
          name="coordinatorEdit"
          label="Change Coordinator"
          strongLabel={true}
          checked={this.state.modifyCoordinator}
          onChange={this.onModifyCoordinator} />
        <Dropdown
          name="room"
          label="Select Room"
          strongLabel={true}
          readOnly={!this.state.modifyRoom}
          value={this.state.selectedRoom}
          onChange={this.onRoomChange}
          options={roomOptions}/>
        <Dropdown
          name="vlj"
          label="Select VLJ"
          strongLabel={true}
          readOnly={!this.state.modifyVlj}
          value={this.state.selectedVLJ}
          onChange={this.onVljChange}
          options={vljOptions}/>
        <Dropdown
          name="coordinator"
          label="Select Hearing Coordinator"
          strongLabel={true}
          readOnly={!this.state.modifyCoordinator}
          value={this.state.selectedCoordinator}
          onChange={this.onCoordinatorChange}
          options={coordinatorOptions}/>
        <TextareaField
          name="Notes"
          strongLabel={true}
          onChange={this.onNotesChange}
          textAreaStyling={notesFieldStyling}
          value={this.state.notes} />
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
  selectedHearingDay: state.hearingSchedule.selectedHearingDay
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onSelectedHearingDayChange,
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HearingDayEditModal));