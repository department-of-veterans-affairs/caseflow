import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY.json';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../../components/Alert';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import { SPREADSHEET_TYPES } from '../constants';

export default class ReviewAssignments extends React.Component {

  getAlertTitle = () => {
    if (this.props.schedulePeriod.type === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
      return COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_TITLE_ROCO;
    }
    if (this.props.schedulePeriod.type === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      return COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_TITLE_JUDGE;
    }
  };

  getAlertMessage = () => {
    if (this.props.schedulePeriod.type === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
      return <p>{COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_MESSAGE_ROCO}</p>;
    }
    if (this.props.schedulePeriod.type === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      return <p>{COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_MESSAGE_JUDGE}</p>;
    }
  };

  getAlertButtons = () => {
    return <div>
      <Link
        name="go-back"
        button="secondary"
        to="/schedule/build/upload">
        Go back
      </Link>
      <Button
        name="confirmAssignments"
        button="primary"
        willNeverBeLoading
        onClick={this.props.onClickConfirmAssignments}
      >
        Confirm assignments
      </Button>
    </div>;
  };

  modalConfirmButton = () => {
    return <Button
      classNames={['usa-button-secondary']}
      onClick={this.props.onConfirmAssignmentsUpload}
    >Confirm upload
    </Button>;
  };

  modalCancelButton = () => {
    return <Button linkStyling onClick={this.props.onClickCloseModal}>Go back</Button>;
  };

  modalMessage = () => {
    return <div>
      <p>{COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_MODAL_BODY}</p>
      <p><b>Schedule type: </b>{SPREADSHEET_TYPES[this.props.schedulePeriod.type].display}</p>
      <p><b>Date range: </b>{this.props.schedulePeriod.startDate} to {this.props.schedulePeriod.endDate}</p>
    </div>;
  };

  render() {
    return <AppSegment filledBackground>
      {this.props.displayConfirmationModal && <div className="cf-modal-scroll">
        <Modal
          title={COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_MODAL_TITLE}
          closeHandler={this.props.onClickCloseModal}
          noDivider
          confirmButton={this.modalConfirmButton()}
          cancelButton={this.modalCancelButton()}
        >
          {this.modalMessage()}
        </Modal>
      </div>}
      <Alert
        type="info"
        title={this.getAlertTitle()}
        message={<div>{this.getAlertMessage()}{this.getAlertButtons()}</div>}
      />
    </AppSegment>;
  }
}

ReviewAssignments.propTypes = {
  schedulePeriod: PropTypes.object,
  displayConfirmationModal: PropTypes.bool,
  onClickConfirmAssignments: PropTypes.func,
  onClickCloseModal: PropTypes.func,
  onConfirmAssignmentsUpload: PropTypes.func
};
