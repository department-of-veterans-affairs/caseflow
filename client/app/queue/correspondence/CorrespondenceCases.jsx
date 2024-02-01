import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { loadCorrespondenceConfig } from './correspondenceReducer/correspondenceActions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import CorrespondenceTableBuilder from './CorrespondenceTableBuilder';
import Alert from '../../components/Alert';

const CorrespondenceCases = (props) => {
  const dispatch = useDispatch();
  const configUrl = props.configUrl;

  const currentAction = useSelector((state) => state.reviewPackage.lastAction);
  const veteranInformation = useSelector((state) => state.reviewPackage.veteranInformation);

  const [vetName, setVetName] = useState('');

  useEffect(() => {
    dispatch(loadCorrespondenceConfig(configUrl));
  }, []);

  const config = useSelector((state) => state.intakeCorrespondence.correspondenceConfig);

  useEffect(() => {
    if (
      veteranInformation?.veteran_name?.first_name &&
      veteranInformation?.veteran_name?.last_name
    ) {
      setVetName(`${veteranInformation.veteran_name.first_name.trim()} ${veteranInformation.veteran_name.last_name.trim()}`);
    }
  }, [veteranInformation]);

  return (
    <>
      <AppSegment filledBackground>
        {(veteranInformation?.veteran_name?.first_name && veteranInformation?.veteran_name?.last_name) &&
          currentAction.action_type === 'DeleteReviewPackage' && (
          <Alert
            type="success"
            title={sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE_BANNER, vetName)}
            message={COPY.CORRESPONDENCE_MESSAGE_REMOVE_PACKAGE_BANNER}
            scrollOnAlert={false}
          />
        )}
        {config &&
        <CorrespondenceTableBuilder />}
      </AppSegment>
    </>
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
