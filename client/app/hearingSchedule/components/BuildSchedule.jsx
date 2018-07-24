import React from 'react';
import _ from 'lodash';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import COPY from '../../../COPY.json';
import Table from '../../components/Table';
import { formatDateStr, formatDate } from '../../util/DateUtil';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import DropdownButton from '../../components/DropdownButton';
import Alert from '../../components/Alert';
import { downloadIcon } from '../../components/RenderFunctions';
import { COLORS } from '../../constants/AppConstants';
import { SPREADSHEET_TYPES } from '../constants';

export default class BuildSchedule extends React.Component {

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
      },
      {
        title: SPREADSHEET_TYPES.JudgeSchedulePeriod.display,
        target: SPREADSHEET_TYPES.JudgeSchedulePeriod.template
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

    const pastUploadsRows = _.map(pastUploads, (pastUpload) => ({
      date: `${formatDateStr(pastUpload.startDate)} - ${formatDateStr(pastUpload.endDate)}`,
      type: SPREADSHEET_TYPES[pastUpload.type].shortDisplay,
      uploaded: formatDate(pastUpload.createdAt),
      uploadedBy: pastUpload.userFullName,
      download: <Link name="download">Download {downloadIcon(COLORS.PRIMARY)}</Link>
    }));

    const displayJudgeSuccessMessage = displaySuccessMessage &&
      schedulePeriod.type === SPREADSHEET_TYPES.JudgeSchedulePeriod.value;

    const displayRoCoSuccessMessage = displaySuccessMessage &&
      schedulePeriod.type === SPREADSHEET_TYPES.RoSchedulePeriod.value;

    const roSuccessMessage = <div>
      You can view your uploaded schedule by clicking the link below.
      <br/>
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
          ${schedulePeriod.startDate} and ${schedulePeriod.endDate}`}
        message={roSuccessMessage}
        styling={alertStyling}
      />}
      {displayRoCoSuccessMessage && <Alert
        type="success"
        title={`You have successfully assigned hearings between
          ${schedulePeriod.startDate} and ${schedulePeriod.endDate}`}
        message={roSuccessMessage}
        styling={alertStyling}
      />}
      <h1>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_HEADER}</h1>
      <h2>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_BUILD_HEADER}</h2>
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
      />
    </AppSegment>;
  }
}

BuildSchedule.propTypes = {
  pastUploads: PropTypes.shape({
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
