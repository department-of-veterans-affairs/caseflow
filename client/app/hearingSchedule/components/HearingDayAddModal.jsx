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
import Dropdown from '../../components/Dropdown'
import TextareaField from '../../components/TextareaField';
import {bindActionCreators} from "redux";
import { onSelectedHearingDayChange, setModalErrors } from "../actions";
import { onRegionalOfficeChange } from '../../components/common/actions'

const notesFieldStyling = css({
  height: '100px',
  fontSize: '10pt'
});

const spanStyling = css({
  marginBotton: '5px'
})

const hearingTypeOptions = [
    {displayText: "", value: ""},
    {displayText: "Video", value: "V"},
    {displayText: "Central", value: "C"}
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

class HearingDayAddModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      videoSelected: false,
      selectedHearingType: '',
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
    this.validateForm();

    if (this.props.modalErrors && this.props.modalErrors.length > 0) {
      return;
    }

    console.log("state at confirm is: ", this.state);
    console.log("redux RO: ", this.props.selectedRegionalOffice);
    console.log("redux Hearing Day added: ", this.props.selectedHearingDay);
    this.props.closeModal();
  };

  validateForm = () => {
    if (this.props.selectedHearingDay === '') {
      this.setErrorMessages('Please make sure you have entered a Hearing Date');
    }

    if (this.state.selectedHearingType === '') {
      this.setErrorMessages('Please make sure you have entered a Hearing Date');
    }

    if (!this.props.selectedRegionalOffice) {
      this.setErrorMessages('Please make sure you select a Regional Office');
    }
  };

  setErrorMessages = (errorMessage) => {
    let newErrors = this.props.modalErrors ? this.props.modalErrors.slice(0) : [];
    newErrors.push(errorMessage);
    this.props.setModalErrors(newErrors);
  }

  getAlertTitle = () => {
    if (this.state.videoSelected) {
      return 'Hearing type is a Video hearing'
    } else {
      return 'Cannot create New Hearing Day'
    }
  };

  getAlertMessage = () => {
    return <ul>
      {
        this.state.errorMessages.map((item, i) => <ListItem key={i} value={item} />)
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
    this.setState({selectedHearingType: value});
    if (value === 'V') {
      this.setState({videoSelected: true});
    } else {
      this.setState({videoSelected: false});
    }
  };

  onVljChange = (value) => {
    this.setState({selectedVLJ: value});
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
        <p {...spanStyling} >Please select the details of the new hearing day </p>
        {
          this.state.error &&
            <StatusMessage
              title= {this.getAlertTitle()}
              type="alert"
              messageText={this.getAlertMessage()}
              wrapInAppSegment={false} >
            </StatusMessage>
        }
        <b {...titleStyling} >Select Hearing Date</b>
        <DateSelector
          name="hearingDate"
          label={false}
          value={this.props.selectedHearingDay}
          onChange={(option) => option && this.props.onSelectedHearingDayChange(option)}
          type="date"
        />
        <Dropdown
          name="hearingType"
          label="Select Hearing Type"
          strongLabel={true}
          value={this.state.selectedHearingType}
          onChange={this.onHearingTypeChange}
          options={hearingTypeOptions}/>
        {
          this.state.error && this.state.videoSelected &&
          <StatusMessage
            title= {this.getAlertTitle}
            type="alert"
            messageText={this.getAlertMessage}
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
        {this.state.videoSelected &&
        <Dropdown
          name="vlj"
          label="Select VLJ (Optional)"
          strongLabel={true}
          value={this.state.selectedVLJ}
          onChange={this.onVljChange}
          options={vljOptions}/>
        }
        {this.state.videoSelected &&
        <Dropdown
          name="coordinator"
          label="Select Hearing Coordinator (Optional)"
          strongLabel={true}
          value={this.state.selectedCoordinator}
          onChange={this.onCoordinatorChange}
          options={coordinatorOptions}/>
        }
        <TextareaField
          name="Notes (Optional)"
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
  modalErrors: state.hearingSchedule.modalErrors
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onSelectedHearingDayChange,
  onRegionalOfficeChange,
  setModalErrors
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HearingDayAddModal));