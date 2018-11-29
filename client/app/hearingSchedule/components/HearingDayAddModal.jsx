import React from 'react';
import { withRouter } from "react-router-dom";
import connect from 'react-redux/es/connect/connect';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';
import COPY from '../../../COPY.json';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import {fullWidth} from "../../queue/constants";
import RoSelectorDropdown from "../../components/RoSelectorDropdown";
import DateSelector from "../../components/DateSelector";
import Dropdown from '../../components/Dropdown'
import type {State} from "../../queue/types/state";
import {bindActionCreators} from "redux";
import { onSelectedHearingDayChange } from "../actions";

const tableStyling = css({
  '& > thead > tr > th': { backgroundColor: '#f1f1f1' },
  border: '1px solid #dadbdc'
});

const hearingTypeOptions = [{displayText: "Video", value: "V"}, {displayText: "Central", value: "C"}];

const titleStyling = css({
  marginBottom: 0,
  padding: 0
});

const centralOfficeStaticEntry = [{
  label: 'Central',
  value: 'C'
}];

class HearingDayModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      videoSelected: false,
      selectedHearingType: ''
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
    this.props.closeModal();
  };

  modalCancelButton = () => {
    return <Button linkStyling onClick={this.onCancelModal}>Go back</Button>;
  };

  onCloseModal = () => {
    this.props.closeModal();
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

  modalMessage = () => {
    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
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
          label="Select HearingType"
          strongLabel="true"
          value={this.state.selectedHearingType}
          onChange={this.onHearingTypeChange}
          options={hearingTypeOptions}/>
        {this.state.videoSelected && <b {...titleStyling} >Select Regional Office (RO)</b>}
        {this.state.videoSelected &&
        <RoSelectorDropdown
          onChange={this.props.onRegionalOfficeChange}
          value={this.props.selectedRegionalOffice}
          staticOptions={centralOfficeStaticEntry} />
        }
      </div>
    </React.Fragment>
  };

  render() {

    const { spErrorDetails } = this.props;
    let title = 'Invalid entries';

    return <AppSegment filledBackground>
      <div className="cf-modal-scroll">
        <Modal
          title="Add Hearing Day"
          closeHandler={this.onCloseModal}
          noDivider
          confirmButton={this.modalConfirmButton()}
          cancelButton={this.modalCancelButton()}
        >
          {this.modalMessage()}
        </Modal>
      </div>
    </AppSegment>;
  }
}

HearingDayModal.propTypes = {
  userId: PropTypes.number,
  userCssId: PropTypes.string,
  closeModal: PropTypes.func,
  cancelModal: PropTypes.func
};

const mapStateToProps = (state: State, ownProps: Params) => ({
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  regionalOffices: state.components.regionalOffices,
  selectedHearingDay: state.hearingSchedule.selectedHearingDay
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onSelectedHearingDayChange
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HearingDayModal));