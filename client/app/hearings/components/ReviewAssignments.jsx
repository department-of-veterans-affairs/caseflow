import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';
import COPY from '../../../COPY';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../../components/Alert';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import Table from '../../components/Table';
import StatusMessage from '../../components/StatusMessage';
import { formatDateStr } from '../../util/DateUtil';
import { REQUEST_TYPE_LABELS, SPREADSHEET_TYPES } from '../constants';

const tableStyling = css({
  '& > thead > tr > th': { backgroundColor: '#f1f1f1' },
  border: '1px solid #dadbdc'
});

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
    return <React.Fragment>
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
    </React.Fragment>;
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

    const { spErrorDetails } = this.props;
    let title = 'The assignments algorithm was unable to run successfully.';

    if (this.props.schedulePeriodError) {
      let message = <span>Please confirm the information in the spreadsheet is valid and
        <Link to="/schedule/build/upload"> try again</Link>. If the issue persists, please
        contact the Caseflow team via the VA Enterprise Service Desk at 855-673-4357
        or by creating a ticket
        via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
      </span>;

      if (spErrorDetails) {
        if (this.props.spErrorDetails.type === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
          message = <span>You have allocated too many hearing days to the {spErrorDetails.details.ro_key},
          the maximum number of allocations is {spErrorDetails.details.max_allocation}.<br></br>
          Please check your spreadsheet and upload the file again using the "Go back" link below.<br></br>
          <Link to="/schedule/build/upload"> Go back</Link>
          </span>;
        } else if (this.props.spErrorDetails.type === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
          title = 'We were unable to assign judges to the schedule.';

          message = <span>We could not assign a judge to every hearing day. Please check the following dates in<br></br>
          your file and try again using the "Go back" link below:<br></br>
            {spErrorDetails.details.dates &&
            spErrorDetails.details.dates.map((date, i) => <span key={i}>{date}<br></br></span>)}
            <span className="cf-push-left" ><Link to="/schedule/build/upload">{'<'} Go back</Link></span>
          </span>;
        }
      }

      return <StatusMessage
        type="alert"
        title={title}
        messageText={message}
      />;
    }

    if (this.props.schedulePeriod.finalized) {
      return <StatusMessage
        type="status"
        title="This page has expired."
        messageText={<Link to="/schedule">Go back to home</Link>}
      />;
    } else if (this.props.schedulePeriod.canFinalize === false) {
      return <StatusMessage
        type="status"
        title="Schedule is being submitted to VACOLS."
        messageText={<Link to="/schedule">Go back to home</Link>}
      />;
    }

    let hearingAssignmentColumns = [
      {
        header: 'Date',
        align: 'left',
        valueName: 'date'
      },
      {
        header: 'Type',
        align: 'left',
        valueName: 'type'
      },
      {
        header: 'Regional Office',
        align: 'left',
        valueName: 'regionalOffice'
      },
      {
        header: 'Room',
        align: 'left',
        valueName: 'room'
      },
    ];

    if (this.props.schedulePeriod.type === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      hearingAssignmentColumns.push({
        header: 'VLJ',
        align: 'left',
        valueName: 'judge'
      });
    } else {
      hearingAssignmentColumns.push(
        {
          header: 'Number of Time Slots',
          align: 'left',
          valueName: 'numberOfSlots'
        },
        {
          header: 'Length of Time Slots (Minutes)',
          align: 'left',
          valueName: 'slotLengthMinutes'
        },
        {
          header: 'Start Time (Eastern)',
          align: 'left',
          valueName: 'firstSlotTime'
        },
      );

    }

    const hearingAssignmentRows = _.map(this.props.schedulePeriod.hearingDays, (hearingDay) => ({
      date: formatDateStr(hearingDay.scheduledFor),
      type: REQUEST_TYPE_LABELS[hearingDay.requestType],
      regionalOffice: hearingDay.regionalOffice,
      room: hearingDay.room,
      judge: hearingDay.judgeName,
      firstSlotTime: hearingDay.firstSlotTime,
      numberOfSlots: hearingDay.numberOfSlots,
      slotLengthMinutes: hearingDay.slotLengthMinutes,
    }));

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
      <Table
        styling={tableStyling}
        columns={hearingAssignmentColumns}
        rowObjects={hearingAssignmentRows}
        summary="hearing-assignments"
        slowReRendersAreOk
      />
    </AppSegment>;
  }
}

ReviewAssignments.defaultProps = {
  schedulePeriod: {}
};

ReviewAssignments.propTypes = {
  schedulePeriod: PropTypes.object,
  schedulePeriodError: PropTypes.bool,
  displayConfirmationModal: PropTypes.bool,
  onClickConfirmAssignments: PropTypes.func,
  onClickCloseModal: PropTypes.func,
  onConfirmAssignmentsUpload: PropTypes.func,
  spErrorDetails: PropTypes.object
};
