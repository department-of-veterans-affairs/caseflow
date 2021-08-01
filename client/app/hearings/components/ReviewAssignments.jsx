import React from 'react';
import PropTypes from 'prop-types';
import { noop } from 'lodash';
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
import { SPREADSHEET_TYPES, REQUEST_TYPE_LABELS } from '../constants';

const tableStyling = css({
  '& > thead > tr > th': { backgroundColor: '#f1f1f1' },
  border: '1px solid #dadbdc',
});

export const AssignmentAlert = ({ type, onClickConfirmAssignments, onClickGoBack }) => {
  const title =
    type === SPREADSHEET_TYPES.RoSchedulePeriod.value ?
      COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_TITLE_ROCO :
      COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_TITLE_JUDGE;

  const message =
    type === SPREADSHEET_TYPES.RoSchedulePeriod.value ? (
      <p>{COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_MESSAGE_ROCO}</p>
    ) : (
      <p>{COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_MESSAGE_JUDGE}</p>
    );

  return (
    <Alert
      type="info"
      title={title}
      message={
        <div>
          {message}
          <Link name="go-back" button="secondary" to="/schedule/build/upload" onClick={onClickGoBack}>
            Go back
          </Link>
          <Button
            name="confirmAssignments"
            button="primary"
            willNeverBeLoading
            onClick={onClickConfirmAssignments}
          >
            Confirm assignments
          </Button>
        </div>
      }
    />
  );
};

AssignmentAlert.defaultProps = {
  onClickGoBack: noop
};

export const AssignmentError = ({ spErrorDetails }) => {
  let title = 'The assignments algorithm was unable to run successfully.';

  let message = (
    <span>
      Please confirm the information in the spreadsheet is valid and
      <Link to="/schedule/build/upload"> try again</Link>. If the issue
      persists, please contact the Caseflow team via the VA Enterprise Service
      Desk at 855-673-4357 or by creating a ticket via{' '}
      <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">
        YourIT
      </a>
      .
    </span>
  );

  if (spErrorDetails) {
    if (spErrorDetails.type === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
      message = (
        <span>
          You have allocated too many hearing days to the{' '}
          {spErrorDetails.details.ro_key}, the maximum number of allocations is{' '}
          {spErrorDetails.details.max_allocation}.<br />
          Please check your spreadsheet and upload the file again using the "Go
          back" link below.
          <br />
          <Link to="/schedule/build/upload"> Go back</Link>
        </span>
      );
    }
  }

  return <StatusMessage type="alert" title={title} messageText={message} />;
};

export const AssignmentsModal = ({
  onClick,
  onClickCloseModal,
  schedulePeriod,
}) => (
  <div className="cf-modal-scroll">
    <Modal
      title={COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_MODAL_TITLE}
      closeHandler={onClickCloseModal}
      noDivider
      confirmButton={<Button classNames={['usa-button-secondary']} onClick={onClick}>Confirm upload</Button>}
      cancelButton={<Button linkStyling onClick={onClickCloseModal}> Go back </Button>}
    >
      <div>
        <p>{COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_MODAL_BODY}</p>
        <p>
          <b>Schedule type: </b>
          {SPREADSHEET_TYPES[schedulePeriod.type].display}
        </p>
        <p>
          <b>Date range: </b>
          {schedulePeriod.startDate} to {schedulePeriod.endDate}
        </p>
      </div>
    </Modal>
  </div>
);

export const ReviewAssignments = ({
  schedulePeriod,
  displayConfirmationModal,
  onClickCloseModal,
  onConfirmAssignmentsUpload,
  spErrorDetails,
  schedulePeriodError,
  onClickConfirmAssignments,
  onClickGoBack
}) => {
  if (schedulePeriodError) {
    return <AssignmentError spErrorDetails={spErrorDetails} />;
  }

  let columns = [
    {
      header: 'Date',
      align: 'left',
      valueName: 'date',
    },
    {
      header: 'Type',
      align: 'left',
      valueName: 'type',
    },
    {
      header: 'Regional Office',
      align: 'left',
      valueName: 'regionalOffice',
    },
  ];

  if (schedulePeriod.type === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
    columns.push({
      header: 'VLJ',
      align: 'left',
      valueName: 'judge',
    });
  } else {
    columns.push(
      {
        header: 'Number of Time Slots',
        align: 'left',
        valueName: 'numberOfSlots',
      },
      {
        header: 'Length of Time Slots (Minutes)',
        align: 'left',
        valueName: 'slotLengthMinutes',
      },
      {
        header: 'Start Time (Eastern)',
        align: 'left',
        valueName: 'firstSlotTime',
      }
    );
  }

  const hearingAssignmentRows = schedulePeriod.hearingDays.map((hearingDay) => ({
    date: formatDateStr(hearingDay.scheduledFor),
    type: REQUEST_TYPE_LABELS[hearingDay.requestType],
    regionalOffice: hearingDay.regionalOffice,
    room: hearingDay.room,
    judge: hearingDay.judgeName,
    firstSlotTime: hearingDay.firstSlotTime,
    numberOfSlots: hearingDay.numberOfSlots,
    slotLengthMinutes: hearingDay.slotLengthMinutes,
  }));

  return (
    <AppSegment filledBackground>
      {displayConfirmationModal && (
        <AssignmentsModal
          onClick={onConfirmAssignmentsUpload}
          onClickCloseModal={onClickCloseModal}
          schedulePeriod={schedulePeriod}
        />
      )}
      <AssignmentAlert
        onClickGoBack={onClickGoBack}
        type={schedulePeriod.type}
        onClickConfirmAssignments={onClickConfirmAssignments}
      />
      <Table
        styling={tableStyling}
        columns={columns}
        rowObjects={hearingAssignmentRows}
        summary="hearing-assignments"
        slowReRendersAreOk
      />
    </AppSegment>
  );
};

ReviewAssignments.defaultProps = {
  schedulePeriod: {},
};

ReviewAssignments.propTypes = {
  schedulePeriod: PropTypes.object,
  schedulePeriodError: PropTypes.bool,
  displayConfirmationModal: PropTypes.bool,
  onClickConfirmAssignments: PropTypes.func,
  onClickCloseModal: PropTypes.func,
  onClickGoBack: PropTypes.func,
  onConfirmAssignmentsUpload: PropTypes.func,
  spErrorDetails: PropTypes.object,
};
