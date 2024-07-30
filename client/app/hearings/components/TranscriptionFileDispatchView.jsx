import React, { useEffect, useState } from 'react';
import QueueOrganizationDropdown from '../../queue/components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';
import TabWindow from '../../components/TabWindow';
import { tabConfig } from './TranscriptionFileDispatchTabs';
import Alert from '../../components/Alert';
import PackageFilesModal from './transcriptionProcessing/PackageFilesModal';
import ApiUtil from '../../util/ApiUtil';

const defaultAlert = {
  title: '',
  message: '',
  type: '',
};

export const TranscriptionFileDispatchView = () => {
  const [alert, setAlert] = useState(defaultAlert);
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [packageModalConfig, setPackageModalConfig] = useState({ opened: false });
  const [contractors, setContractors] = useState([]);

  const getContractors = () => {
    ApiUtil.get('/hearings/find_by_contractor/available_contractors').
      // eslint-disable-next-line camelcase
      then((response) => setContractors(response.body?.transcription_contractors));
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

  const buildPackage = () => {
    // build the package
  };

  const openPackageModal = () => {
    setPackageModalConfig({ opened: true });
  };

  const closePackageModal = () => {
    setPackageModalConfig({ opened: false });
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

      <AppSegment filledBackground >
        <h1 {...css({ display: 'inline-block' })}>Transcription file dispatch</h1>
        <QueueOrganizationDropdown organizations={[{ name: 'Transcription', url: 'transcription-team' }]} />
        <TabWindow
          name="transcription-tabwindow"
          defaultPage={0}
          fullPage={false}
          tabs={tabConfig(openPackageModal, selectFilesForPackage, selectedFiles.length)}
        />
        { packageModalConfig.opened && <PackageFilesModal onCancel={closePackageModal} contractors={contractors} />}
      </AppSegment>
    </>
  );
};
