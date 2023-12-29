import React from 'react';
import PropTypes, { object } from 'prop-types';
import BatchSize from './BatchSize';
import DocketTimeGoals from './DocketTimeGoals';
import AffinityDays from './AffinityDays';
import LeverButtonsWrapper from './LeverButtonsWrapper';
import ExclusionTable from './ExclusionTable';

const InteractableLeverWrapper = ({ levers, leverStore, isAdmin, sectionTitles, loadedLevers }) => {

  return (
    <div>
      <ExclusionTable isAdmin={isAdmin} />
      <BatchSize loadedLevers={loadedLevers.batch} leverList={levers.batchSizeLevers} leverStore={leverStore} isAdmin={isAdmin} />
      <AffinityDays loadedLevers={loadedLevers.affinity} leverList={levers.affinityLevers} leverStore={leverStore} isAdmin={isAdmin} />
      <DocketTimeGoals loadedLevers={loadedLevers.docket_time_goal} leverList={levers.docketLeversObject} leverStore={leverStore} isAdmin={isAdmin}
        sectionTitles={sectionTitles} />
      {isAdmin ? <LeverButtonsWrapper leverStore={leverStore} /> : ''}
    </div>
  );
};

InteractableLeverWrapper.propTypes = {
  levers: PropTypes.array.isRequired,
  leverStore: PropTypes.any,
  isAdmin: PropTypes.bool,
  sectionTitles: PropTypes.array.isRequired,
  loadedLevers: PropTypes.arrayOf(object).isRequired
};

export default InteractableLeverWrapper;
