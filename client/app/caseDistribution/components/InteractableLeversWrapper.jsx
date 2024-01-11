import React from 'react';
import PropTypes from 'prop-types';
import BatchSize from './BatchSize';
import DocketTimeGoals from './DocketTimeGoals';
import AffinityDays from './AffinityDays';
import LeverButtonsWrapper from './LeverButtonsWrapper';
import ExclusionTable from './ExclusionTable';

const InteractableLeverWrapper = ({ levers, leverStore, isAdmin }) => {

  return (
    <div>
      <ExclusionTable isAdmin={isAdmin} />
      <BatchSize isAdmin={isAdmin} />
      <AffinityDays isAdmin={isAdmin} />
      <DocketTimeGoals isAdmin={isAdmin} />
      {isAdmin ? <LeverButtonsWrapper leverStore={leverStore} /> : ''}
    </div>
  );
};

InteractableLeverWrapper.propTypes = {
  levers: PropTypes.object.isRequired,
  leverStore: PropTypes.any,
  isAdmin: PropTypes.bool,
};

export default InteractableLeverWrapper;
