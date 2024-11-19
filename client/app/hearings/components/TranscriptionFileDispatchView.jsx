import React, { useEffect, useState } from 'react';
import QueueOrganizationDropdown from '../../queue/components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';
import TabWindow from '../../components/TabWindow';
import { tabConfig } from './TranscriptionFileDispatchTabs';
import Alert from '../../components/Alert';
import PackageFilesModal from './transcriptionProcessing/PackageFilesModal';
import ApiUtil from '../../util/ApiUtil';
import { getQueryParams, encodeQueryParams } from '../../util/QueryParamsUtil';
import WorkOrderHightlightsModal from './transcriptionProcessing/WorkOrderHighlightsModal';
import PropTypes from 'prop-types';

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

export const TranscriptionFileDispatchView = ({ organizations }) => {
  const [alert, setAlert] = useState(defaultAlert);
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [modalConfig, setModalConfig] = useState({ opened: false, type: '' });
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

  const searchFromUrl = () => {
    let search = '';
    const params = getQueryParams(window.location.search);

    if (params.search) {
      search = params.search;
    }

    return search;
  };

  const [searchValue, setSearchValue] = useState(searchFromUrl());
  const [searchInput, setSearchInput] = useState('');

  /**
   * Fetches available contractors
   */
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
  const openModal = (config) => {
    setModalConfig({ opened: true, ...config });
  };

  // Closes the modal
  const closeModal = () => {
    setModalConfig({ opened: false, type: '' });
  };

  /**
   * @param {object} config - object to describe what type of modal to render
   * @returns the modal
   */
  const renderModal = (config) => {
    switch (config.type) {
    case 'package':
      return (
        <PackageFilesModal
          onCancel={closeModal}
          contractors={contractors.transcription_contractors}
          returnDates={contractors.return_dates}
          selectedFiles={selectedFiles}
        />
      );
    case 'highlights':
      return (
        <WorkOrderHightlightsModal
          onCancel={closeModal}
          workOrder={config.workOrder}
        />
      );
    default: return <></>;
    }
  };

  const onTabChange = () => {
    // reset pagenation, filtering and search settings when tab changes
    const base = `${window.location.origin}${window.location.pathname}`;
    const params = getQueryParams(window.location.search);
    const qs = encodeQueryParams({ tab: params.tab, page: 1 });

    setSearchValue('');

    history.pushState('', '', `${base}${qs}`);
  };

  const handleSearchBarChange = (input) => {
    // save value for use on search submit
    setSearchInput(input);
  };

  const handleSearchBarSubmit = () => {
    // use saved search input value and update URL params and pass search to children
    // making sure to reset page to 1 as well to avoid weird page states

    const currentParams = new URLSearchParams(window.location.search);

    currentParams.set('page', 1);
    currentParams.set('search', searchInput);
    const qs = currentParams.toString();

    history.replaceState('', '', `?${qs}`);

    setSearchValue(searchInput);
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
          <QueueOrganizationDropdown organizations={organizations} />
        </div>
        <TabWindow
          name="transcription-tabwindow"
          defaultPage={currentTab}
          fullPage={false}
          onChange={onTabChange}
          tabs={tabConfig(
            openModal,
            selectFilesForPackage,
            selectedFiles.length,
            {
              value: searchValue,
              onChange: handleSearchBarChange,
              onSubmit: handleSearchBarSubmit
            }
          )}
        />
        { modalConfig.opened && renderModal(modalConfig)}
      </AppSegment>
    </>
  );
};

TranscriptionFileDispatchView.propTypes = {
  organizations: PropTypes.array
};
