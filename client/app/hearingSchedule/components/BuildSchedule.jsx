import React from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import COPY from '../../../COPY.json';
import Table from '../../components/Table';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import DropdownButton from '../../components/DropdownButton';
import { downloadIcon } from '../../components/RenderFunctions';
import { COLORS } from '../../constants/AppConstants';

export default class BuildSchedule extends React.Component {

  render() {
    const {
      pastUploads
    } = this.props;

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
        valueName: 'uploaded_by'
      },
      {
        header: '',
        align: 'left',
        valueName: 'download'
      }
    ];
    const downloadOptions = [
      {
        title: 'RO/CO hearings',
        value: 'RO/CO hearings',
        target: '/hearings/roco' },
      {
        title: 'Judge Non-availability',
        value: 'Judge Non-availability',
        target: '/hearings/judge' }
    ];

    const pastUploadsRows = pastUploads.map((pastUpload) => {
      return {
        date: `${pastUpload.startDate} - ${pastUpload.endDate}`,
        type: pastUpload.type,
        uploaded: pastUpload.createdAt,
        uploaded_by: pastUpload.user,
        download: <Link name="download">Download {downloadIcon(COLORS.PRIMARY)}</Link>
      };
    });

    return <AppSegment filledBackground>
      <h1>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_HEADER}</h1>
      <h2>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_BUILD_HEADER}</h2>
      <p>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_BUILD_DESCRIPTION}</p>
      <DropdownButton
        lists={downloadOptions}
        onClick={this.handleMenuClick}
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
  pastUploads: PropTypes.arrayOf(
    PropTypes.shape({
      type: PropTypes.string,
      user: PropTypes.string,
      startDate: PropTypes.date,
      endDate: PropTypes.date,
      createdAt: PropTypes.date,
      fileName: PropTypes.string
    })
  )
};
