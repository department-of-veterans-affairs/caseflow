import React, { useEffect, useState } from 'react';
import QueueOrganizationDropdown from '../../queue/components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';
import TabWindow from '../../components/TabWindow';
import { tabConfig } from './TranscriptionFileDispatchTabs';
import Alert from '../../components/Alert';
import PackageFilesModal from './transcriptionProcessing/PackageFilesModal';
import ApiUtil from '../../util/ApiUtil';
import { getQueryParams } from '../../util/QueryParamsUtil';

const defaultAlert = {
  title: '',
  message: '',
  type: '',
};

const styles = css({
  '& .cf-dropdown': {
    marginRight: 0
  },
  '& h1': {
    display: 'inline-block',
    marginBottom: 0
  }
});

export const TranscriptionFileDispatchView = () => {
  const [alert, setAlert] = useState(defaultAlert);
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [packageModalConfig, setPackageModalConfig] = useState({ opened: false });
  const [contractors, setContractors] = useState({ transcription_contractors: [], return_dates: ['---', '---'] });

  const tabFromUrl = () => {
    const params = getQueryParams(window.location.search);
    let page = 0;

    if (params.tab === 'Assigned') {
      page = 1;
    } else if (params.tab === 'Completed') {
      page = 2;
    } else if (params.tab === 'All') {
      page = 3;
    }

    return page;
  };
  const [currentTab] = useState(tabFromUrl());

  const getContractors = () => {
    ApiUtil.get('/hearings/find_by_contractor/available_contractors').
      // eslint-disable-next-line camelcase
      then((response) => setContractors(response.body));
  };

  const selectFilesForPackage = (files) => {
    setSelectedFiles(files.filter((file) => file.status === 'selected'));
    if (files.filter((file) => file.status === 'locked').length) {
      setAlert({
        title: 'Another user is in the assignment queue.',
        message: 'Some files may not be available for assignment.',
        type: 'warning'
      });
    } else {
      setAlert(defaultAlert);
    }
  };

  // Opens the modal
  const openPackageModal = () => {
    setPackageModalConfig({ opened: true });
  };

  // Closes the modal
  const closePackageModal = () => {
    setPackageModalConfig({ opened: false });
  };

  const onTabChange = (tabNumber) => {
    console.log(tabNumber);
  };

  useEffect(() => {
    getContractors();
  }, []);

  return (
    <>
      {alert.title && (
        <Alert
          title={alert.title}
          message={alert.message}
          type={alert.type}
        />
      )}

      <AppSegment filledBackground>
        <div {...styles}>
          <h1>Transcription file dispatch</h1>
          <QueueOrganizationDropdown organizations={[{ name: 'Transcription', url: 'transcription-team' }]} />
        </div>
        <TabWindow
          name="transcription-tabwindow"
          defaultPage={currentTab}
          fullPage={false}
          onChange={onTabChange}
          tabs={tabConfig(openPackageModal, selectFilesForPackage, selectedFiles.length)}
        />
        { packageModalConfig.opened &&
          <PackageFilesModal
            onCancel={closePackageModal}
            contractors={contractors.transcription_contractors}
            returnDates={contractors.return_dates}
            selectedFiles={selectedFiles}
          />}
      </AppSegment>
    </>
  );
};
