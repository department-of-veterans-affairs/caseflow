import React from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import COPY from '../../../COPY.json';
import Button from '../../components/Button';
import Table from '../../components/Table';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

export class BuildSchedule extends React.Component {

  render() {

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

    const pastUploadsRows = [
      {
        date: '10/01/2018-03/31/2019',
        type: 'Judge',
        uploaded: '07/03/2018',
        uploaded_by: 'Justin Madigan',
        download: <Link name="download">Download</Link>
      },
      {
        date: '10/01/2018-03/31/2019',
        type: 'RO/CO',
        uploaded: '07/03/2018',
        uploaded_by: 'Justin Madigan',
        download: <Link name="download">Download</Link>
      }
    ];

    return <AppSegment filledBackground>
      <h1>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_HEADER}</h1>
      <h2>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_BUILD_HEADER}</h2>
      <p>{COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_BUILD_DESCRIPTION}</p>
      <p>
        <Button
          name="download-templates"
          classNames={['usa-button', 'usa-button-outline']}>
          {COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_DOWNLOAD_LINK}
        </Button>
        <Link
          name="upload-files"
          button="primary"
          target="_blank">
          {COPY.HEARING_SCHEDULE_BUILD_WELCOME_PAGE_UPLOAD_LINK}
        </Link>
      </p>
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

export default BuildSchedule;
