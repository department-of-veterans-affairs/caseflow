import React from 'react';
import { withRouter } from "react-router-dom";
import connect from 'react-redux/es/connect/connect';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import COPY from '../../../COPY.json';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import StatusMessage from '../../components/StatusMessage'
import {fullWidth} from "../../queue/constants";
import RoSelectorDropdown from "../../components/RoSelectorDropdown";
import DateSelector from "../../components/DateSelector";
import SearchableDropdown from '../../components/SearchableDropdown'
import TextareaField from '../../components/TextareaField';
import {bindActionCreators} from "redux";
import { onSelectedHearingDayChange,
  selectHearingType,
  selectVlj,
  selectHearingCoordinator,
  setNotes
} from "../actions";
import { onRegionalOfficeChange } from '../../components/common/actions'
import Checkbox from "../../components/Checkbox";

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
    {label: "", value: ""},
    {label: "Video", value: "V"},
    {label: "Central", value: "C"}
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
      error: false,
      errorMessages: [],
      roError: false,
      roomNotRequired: true
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
    let errorMessages = []
    if (this.props.selectedHearingDay === '') {
      errorMessages.push('Please make sure you have entered a Hearing Date');
    }

    if (this.props.hearingType === '') {
      errorMessages.push('Please make sure you have entered a Hearing Type');
    }

    if (this.state.videoSelected && !this.props.selectedRegionalOffice) {
      errorMessages.push('Please make sure you select a Regional Office');
    }

    if (errorMessages.length > 0){
      this.setState({error: true, errorMessages: errorMessages});
      return;
    }

    console.log("state at confirm is: ", this.state);
    console.log("redux RO: ", this.props.selectedRegionalOffice);
    console.log("redux Hearing Day added: ", this.props.selectedHearingDay);

    this.props.closeModal();
  };

  getAlertTitle = () => {
    if (this.state.videoSelected) {
      return <span {...statusMsgTitleStyle}>Hearing type is a Video hearing</span>;
    } else {
      return <span {...statusMsgTitleStyle}>Cannot create New Hearing Day</span>;
    }
  };

  getAlertMessage = () => {
    return <ul {...statusMsgDetailStyle} >
      {
        this.state.errorMessages.map((item, i) => <li key={i}>{item}</li>)
      }
    </ul>
  };

  modalCancelButton = () => {
    return <Button linkStyling onClick={this.onCancelModal}>Go back</Button>;
  };

  onCancelModal = () => {
    this.props.cancelModal();
  };

  onHearingTypeChange = (value) => {
    this.props.selectHearingType(value);

    switch (value.value) {
      case 'V':
        this.setState({videoSelected: true});
        this.setState({centralOfficeSelected: false});
        break;
      case 'C':
        this.setState({videoSelected: false});
        this.setState({centralOfficeSelected: true});
        break;
      default:
        this.setState({videoSelected: false});
        this.setState({centralOfficeSelected: false});
    }
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

  onRoomNotRequired = () => {
    this.setState({roomNotRequired: !this.state.roomNotRequired})
  }

  modalMessage = () => {
    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <p {...spanStyling} >Please select the details of the new hearing day </p>
        <div {...statusMsgTitleStyle}>
        {
          (this.state.error && !this.state.roError) &&
            <StatusMessage
              title= {this.getAlertTitle()}
              type="alert"
              messageText={this.getAlertMessage()}
              wrapInAppSegment={false} >
            </StatusMessage>
        }
        </div>
        <b {...titleStyling} >Select Hearing Date</b>
        <DateSelector
          name="hearingDate"
          label={false}
          value={this.props.selectedHearingDay}
          onChange={(option) => option && this.props.onSelectedHearingDayChange(option)}
          type="date"
        />
        <SearchableDropdown
          name="hearingType"
          label="Select Hearing Type"
          strongLabel={true}
          value={this.props.hearingType}
          onChange={this.onHearingTypeChange}
          options={hearingTypeOptions}/>
        {
          this.state.roError &&
          <StatusMessage
            title= {this.getAlertTitle()}
            type="alert"
            messageText={this.getAlertMessage()}
            wrapInAppSegment={false} >
          </StatusMessage>
        }
        {this.state.videoSelected &&
        <RoSelectorDropdown
          label="Select Regional Office (RO)"
          strongLabel={true}
          onChange={this.props.onRegionalOfficeChange}
          value={this.props.selectedRegionalOffice}
          staticOptions={centralOfficeStaticEntry}/>
        }
        {(this.state.videoSelected || this.state.centralOfficeSelected) &&
        <SearchableDropdown
          name="vlj"
          label="Select VLJ (Optional)"
          strongLabel={true}
          value={this.props.vlj}
          onChange={this.onVljChange}
          options={this.props.activeJudges}/>
        }
        {(this.state.videoSelected || this.state.centralOfficeSelected) &&
        <SearchableDropdown
          name="coordinator"
          label="Select Hearing Coordinator (Optional)"
          strongLabel={true}
          value={this.props.coordinator}
          onChange={this.onCoordinatorChange}
          options={this.props.activeCoordinators}/>
        }
        <TextareaField
          name="Notes (Optional)"
          strongLabel={true}
          onChange={this.onNotesChange}
          textAreaStyling={notesFieldStyling}
          value={this.props.notes} />
        <Checkbox
          name="roomNotRequired"
          label="Board Hearing Room Not Required"
          strongLabel={true}
          value={this.state.roomNotRequired}
          onChange={this.onRoomNotRequired}
          {...roomNotRequiredStyling}/>
      </div>
    </React.Fragment>
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
  activeJudges: state.hearingSchedule.activeJudges,
  activeCoordinators: state.hearingSchedule.activeCoordinators
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onSelectedHearingDayChange,
  onRegionalOfficeChange,
  selectHearingType,
  selectVlj,
  selectHearingCoordinator,
  setNotes
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HearingDayAddModal));