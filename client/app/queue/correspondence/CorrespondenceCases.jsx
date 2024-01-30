import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import ApiUtil from '../../util/ApiUtil';
import { loadVetCorrespondence } from './correspondenceReducer/correspondenceActions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';
import CorrespondenceTable from './CorrespondenceTable';
import QueueOrganizationDropdown from '../components/QueueOrganizationDropdown';
import Alert from '../../components/Alert';

// import {
//   initialAssignTasksToUser,
//   initialCamoAssignTasksToVhaProgramOffice
// } from '../QueueActions';

const CorrespondenceCases = (props) => {
  const organizations = props.organizations;
  const currentAction = useSelector((state) => state.reviewPackage.lastAction);
  const veteranInformation = useSelector((state) => state.reviewPackage.veteranInformation);
  const vetCorrespondences = useSelector((state) => state.intakeCorrespondence.vetCorrespondences);

  const dispatch = useDispatch();

  // grabs correspondences and loads into intakeCorrespondence redux store.
  const getVeteransWithCorrespondence = async () => {
    try {
      const response = await ApiUtil.get('/queue/correspondence?json');
      const returnedObject = response.body;
      const vetCorrespondences = returnedObject.vetCorrespondences;

      dispatch(loadVetCorrespondence(vetCorrespondences));
    } catch (err) {
      console.error(new Error(`Problem with GET /queue/correspondence?json ${err}`));
    }
  };

  // load veteran correspondence info on page load
  useEffect(() => {
    // Retry the request after a delay
    const timer = setTimeout(() => {
      getVeteransWithCorrespondence();
    }, 1000);

    return () => clearTimeout(timer);
  }, []);

  let vetName = '';

  if (Object.keys(veteranInformation).length > 0) {
    vetName = `${veteranInformation.veteran_name.first_name.trim()} ${veteranInformation.veteran_name.last_name.trim()}`;
  }

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
        <h1 {...css({ display: 'inline-block' })}>{COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_CORRESPONDENCE_CASES}</h1>
        <QueueOrganizationDropdown organizations={organizations} />
        {vetCorrespondences && <CorrespondenceTable vetCorrespondences={vetCorrespondences} />}
      </AppSegment>
    </React.Fragment>
  );
};

CorrespondenceCases.propTypes = {
  organizations: PropTypes.array,
  loadVetCorrespondence: PropTypes.func,
  vetCorrespondences: PropTypes.array,
  currentAction: PropTypes.object,
  veteranInformation: PropTypes.object,
  configUrl: PropTypes.string
};

export default CorrespondenceCases;
