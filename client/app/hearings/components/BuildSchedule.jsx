import React from 'react';
import _ from 'lodash';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import COPY from '../../../COPY';
import Table from '../../components/Table';
import { formatDateStr } from '../../util/DateUtil';
import Button from '../../components/Button';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import DropdownButton from '../../components/DropdownButton';
import Alert from '../../components/Alert';
import { downloadIcon } from '../../components/RenderFunctions';
import { COLORS } from '../../constants/AppConstants';
import { SPREADSHEET_TYPES } from '../constants';

export default class BuildSchedule extends React.Component {

  openDownloadLink = (periodId) => {
    window.open(`/hearings/schedule/${periodId}/download.json?download=true`);
  }

  render() {
    const {
      pastUploads,
      displaySuccessMessage,
      schedulePeriod
    } = this.props;

    const linkStyling = css({
      marginTop: '6px'
    });

    const alertStyling = css({
      marginBottom: '20px'
    });

    const downloadOptions = [
      {
        title: SPREADSHEET_TYPES.RoSchedulePeriod.display,
        target: SPREADSHEET_TYPES.RoSchedulePeriod.template
      }
    ];

    const pastUploadsColumns = [
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
        header: 'Uploaded',
        align: 'left',
        valueName: 'uploaded'
      },
      {
        header: 'Uploaded by',
        align: 'left',
        valueName: 'uploadedBy'
      },
      {
        header: '',
        align: 'left',
        valueName: 'download'
      }
    ];

    const pastFinalized = _.filter(pastUploads, (uploads) => uploads.finalized === true);

    const sortPastUploads = _.orderBy(pastFinalized, (sortUploads) => sortUploads.createdAt, 'asc');

    const pastUploadsRows = _.map(sortPastUploads, (pastUpload) => ({
      date: `${formatDateStr(pastUpload.startDate)} - ${formatDateStr(pastUpload.endDate)}`,
      type: SPREADSHEET_TYPES[pastUpload.type].shortDisplay,
      uploaded: formatDateStr(pastUpload.createdAt),
      uploadedBy: pastUpload.userFullName,
      download: <Button name="download"
        linkStyling
        onClick={() => {
          this.openDownloadLink(`${pastUpload.id}`);
        }
        }>
         Download {downloadIcon(COLORS.PRIMARY)}
      </Button>
    }));

    const displayJudgeSuccessMessage = displaySuccessMessage &&
      schedulePeriod.type === SPREADSHEET_TYPES.JudgeSchedulePeriod.value;

    const displayRoCoSuccessMessage = displaySuccessMessage &&
      schedulePeriod.type === SPREADSHEET_TYPES.RoSchedulePeriod.value;

    const successMessage = <div>
      {COPY.HEARING_SCHEDULE_SUCCESS_MESSAGE}
      <br />
      <div {...linkStyling}>
        <Link
          name="view-schedule"
          to="/schedule">
          {COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_SCHEDULE_LINK}</Link>
      </div>
    </div>;

    return <AppSegment filledBackground>
      {displayJudgeSuccessMessage && <Alert
        type="success"
        title={`You have successfully assigned judges to hearings between
          ${formatDateStr(schedulePeriod.startDate)} and ${formatDateStr(schedulePeriod.endDate)}`}
        message={successMessage}
        styling={alertStyling}
      />}
      {displayRoCoSuccessMessage && <Alert
        type="success"
        title={`You have successfully assigned hearings between
          ${formatDateStr(schedulePeriod.startDate)} and ${formatDateStr(schedulePeriod.endDate)}`}
        message={successMessage}
        styling={alertStyling}
      />}
      <h1>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_BUILD_HEADER}</h1>
      <p>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_BUILD_DESCRIPTION}</p>
      <DropdownButton
        lists={downloadOptions}
        label={COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_DOWNLOAD_LINK}
      />
      <Link
        name="upload-files"
        button="primary"
        to="/schedule/build/upload">
        {COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_UPLOAD_LINK}
      </Link>
      <div className="cf-help-divider"></div>
      <h2>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_HISTORY_HEADER}</h2>
      <Link
        name="view-schedule"
        to="/schedule">
        {COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_SCHEDULE_LINK}</Link>
      <Table
        columns={pastUploadsColumns}
        rowObjects={pastUploadsRows}
        summary="past-uploads"
        slowReRendersAreOk
      />
    </AppSegment>;
  }
}

BuildSchedule.propTypes = {
  pastUploads: PropTypes.shape({
    id: PropTypes.number,
    type: PropTypes.string,
    userFullName: PropTypes.string,
    startDate: PropTypes.string,
    endDate: PropTypes.string,
    createdAt: PropTypes.string,
    fileName: PropTypes.string
  }),
  schedulePeriod: PropTypes.object,
  displaySuccessMessage: PropTypes.bool
};
