import React, { useState } from 'react';
import QueueOrganizationDropdown from '../../queue/components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';
import TabWindow from '../../components/TabWindow';
import { tabConfig } from './TranscriptionFileDispatchTabs';
import Alert from '../../components/Alert';

const alertStyle = css({
  '& .usa-alert': {
    paddingBottom: '2rem'
  }
});

const defaultAlert = {
  title: '',
  message: '',
  type: '',
};

export const TranscriptionFileDispatchView = () => {
  const [alert, setAlert] = useState(defaultAlert);
  const [selectedFiles, setSelectedFiles] = useState([]);

  const selectFilesForPackage = (files) => {
    setSelectedFiles(files.filter((file) => file.status === 'selected'));
    if (files.filter((file) => file.status === 'locked').length) {
      setAlert({
        title: 'Another user is in the assignment queue.  Some files may not be available for assignment',
        message: '',
        type: 'warning'
      });
    } else {
      setAlert(defaultAlert);
    }
  };

  const buildPackage = () => {
    // build the package
  };

  return (
    <>
      {alert.title && (
        <div {...alertStyle}>
          <Alert
            title={alert.title}
            message={alert.message}
            type={alert.type}
          />
        </div>
      )}

      <AppSegment filledBackground >
        <h1 {...css({ display: 'inline-block' })}>Transcription file dispatch</h1>
        <QueueOrganizationDropdown organizations={[{ name: 'Transcription', url: 'transcription-team' }]} />
        <TabWindow
          name="transcription-tabwindow"
          defaultPage={0}
          fullPage={false}
          tabs={tabConfig(buildPackage, selectFilesForPackage, selectedFiles.length)}
        />
      </AppSegment>
    </>
  );
};
