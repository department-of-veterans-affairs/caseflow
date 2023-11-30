import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import BatchSize from './BatchSize';
import DocketTimeGoals from './DocketTimeGoals';
import AffinityDays from './AffinityDays';
import LeverButtonsWrapper from './LeverButtonsWrapper';
import ExclusionTable from './ExclusionTable';

const InteractableLeverWrapper = ({ levers, leverStore }) => {
  useEffect(() => {
    console.log('Wrapper State:', leverStore.getState())
  }, [leverStore]);

  return (
    <div>
      <ExclusionTable />
      <h1 key={leverStore.getState().lever_values}>{leverStore.getState().lever_values}</h1>
      <BatchSize leverList={levers.batchSizeLevers} leverStore={leverStore} />
      <AffinityDays leverList={levers.affinityLevers} leverStore={leverStore} />
      <DocketTimeGoals leverList={levers.docketLevers} leverStore={leverStore} />
      <LeverButtonsWrapper leverStore={leverStore} />
    </div>
  );
};

InteractableLeverWrapper.propTypes = {
  levers: PropTypes.array.isRequired,
  leverStore: PropTypes.any
};

export default InteractableLeverWrapper;
