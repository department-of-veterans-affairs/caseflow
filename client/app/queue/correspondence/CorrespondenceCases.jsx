import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import ApiUtil from '../../util/ApiUtil';
import { loadCorrespondenceConfig } from './correspondenceReducer/correspondenceActions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';
// import CorrespondenceTable from './CorrespondenceTable';
// import QueueOrganizationDropdown from '../components/QueueOrganizationDropdown';
import Alert from '../../components/Alert';

// import {
//   initialAssignTasksToUser,
//   initialCamoAssignTasksToVhaProgramOffice
// } from '../QueueActions';

const CorrespondenceCases = (props) => {
  const dispatch = useDispatch();
  const configUrl = props.configUrl;
  const currentAction = useSelector((state) => state.reviewPackage.lastAction);
  const veteranInformation = useSelector((state) => state.reviewPackage.veteranInformation);

  const [vetName, setVetName] = useState('');

  const getCorrespondenceConfig = () => {
    return ApiUtil.get(configUrl)
      .then((response) => {
        const returnedObject = response.body;
        const correspondenceConfig = returnedObject.correspondence_config;

        dispatch(loadCorrespondenceConfig(correspondenceConfig));
      })
      .catch((err) => {
        console.error(new Error(`Problem with GET ${configUrl} ${err}`));
      });
  };

  useEffect(() => {
    // Retry the request after a delay
    setTimeout(() => {
      getCorrespondenceConfig();
    }, 1000);
  }, [configUrl]);

  useEffect(() => {
    if (
      veteranInformation?.veteran_name?.first_name &&
      veteranInformation?.veteran_name?.last_name
    ) {
      setVetName(`${veteranInformation.veteran_name.first_name.trim()} ${veteranInformation.veteran_name.last_name.trim()}`);
    }
  }, [veteranInformation]);

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        {Object.keys(veteranInformation).length > 0 &&
          currentAction.action_type === 'DeleteReviewPackage' && (
            <Alert
              type="success"
              title={sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE_BANNER, vetName)}
              message={COPY.CORRESPONDENCE_MESSAGE_REMOVE_PACKAGE_BANNER}
              scrollOnAlert={false}
            />
          )}
        <h1 {...css({ display: 'inline-block' })}>
          {COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_CORRESPONDENCE_CASES}
        </h1>
          {/* <QueueOrganizationDropdown organizations={organizations} />
          {this.props.correspondenceConfig &&
          <CorrespondenceTable
            correspondenceConfig={this.props.correspondenceConfig}
          />
          } */}
      </AppSegment>
    </React.Fragment>
  );
};

CorrespondenceCases.propTypes = {
  organizations: PropTypes.array,
  loadCorrespondenceConfig: PropTypes.func,
  correspondenceConfig: PropTypes.object,
  currentAction: PropTypes.object,
  veteranInformation: PropTypes.object,
  configUrl: PropTypes.string
};

export default CorrespondenceCases;
