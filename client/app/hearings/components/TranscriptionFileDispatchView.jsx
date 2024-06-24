import React, { useState } from 'react';
import QueueOrganizationDropdown from '../../queue/components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';
import TabWindow from '../../components/TabWindow';
import { tabConfig } from './TranscriptionFileDispatchTabs';

export const TranscriptionFileDispatchView = () => {
  const [selectedFiles, setSelectedFiles] = useState([]);

  const buildPackage = () => {
    // build the package
  };

  const selectFilesForPackage = (files) => {
    setSelectedFiles(files.filter((file) => file.status === 'selected'));
  };

  return (
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
  );
};
