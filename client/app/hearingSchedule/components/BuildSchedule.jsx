import React from 'react';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import COPY from '../../../COPY.json';
import Table from '../../components/Table';
import { formatDate } from '../../util/DateUtil';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import DropdownButton from '../../components/DropdownButton';
import { downloadIcon } from '../../components/RenderFunctions';
import { COLORS } from '../../constants/AppConstants';

const schedulePeriodMapper = {
  RoSchedulePeriod: 'RO/CO',
  JudgeSchedulePeriod: 'Judge'
};

export default class BuildSchedule extends React.Component {

  render() {
    const {
      pastUploads
    } = this.props;

    const downloadOptions = [
      {
        title: 'RO/CO hearings',
        target: '/hearings/roco'
      },
      {
        title: 'Judge non-availability',
        target: '/hearings/judge'
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
      date: `${formatDate(pastUpload.startDate)} - ${formatDate(pastUpload.endDate)}`,
      type: schedulePeriodMapper[pastUpload.type],
      uploaded: formatDate(pastUpload.createdAt),
      uploadedBy: pastUpload.userFullName,
      download: <Link name="download">Download {downloadIcon(COLORS.PRIMARY)}</Link>
    }));

    return <AppSegment filledBackground>
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
        target="_blank">
        {COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_UPLOAD_LINK}
      </Link>
      <div className="cf-help-divider"></div>
      <h2>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_HISTORY_HEADER}</h2>
      <Link
        name="view-schedule">
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
  })
};
