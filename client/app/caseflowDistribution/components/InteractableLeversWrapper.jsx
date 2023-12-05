import React, { useState, useEffect } from 'react';
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
      <BatchSize leverList={levers.batchSizeLevers} leverStore={leverStore} isAdmin={isAdmin} />
      <AffinityDays leverList={levers.affinityLevers} leverStore={leverStore} isAdmin={isAdmin} />
      <DocketTimeGoals leverList={levers.docketLevers} leverStore={leverStore} isAdmin={isAdmin} />
      {isAdmin ? <LeverButtonsWrapper leverStore={leverStore} /> : ''}
    </div>
  );
};

InteractableLeverWrapper.propTypes = {
  levers: PropTypes.array.isRequired,
  leverStore: PropTypes.any,
  isAdmin: PropTypes.bool,
};

export default InteractableLeverWrapper;
