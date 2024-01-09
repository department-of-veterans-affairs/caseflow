import React from 'react';
import { useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import BatchSize from './BatchSize';
import DocketTimeGoals from './DocketTimeGoals';
import AffinityDays from './AffinityDays';
import LeverButtonsWrapper from './LeverButtonsWrapper';
import ExclusionTable from './ExclusionTable';
import { getUserIsAcdAdmin } from '../reducers/levers/leversSelector';

const InteractableLeverWrapper = ({ levers, leverStore, sectionTitles }) => {
  const theState = useSelector((state) => state);
  const isUserAcdAdmin = getUserIsAcdAdmin(theState);

  return (
    <div>
      <ExclusionTable />
      <BatchSize />
      <AffinityDays leverList={levers.affinityLevers} leverStore={leverStore} />
      <DocketTimeGoals
        leverList={levers.docketLeversObject}
        leverStore={leverStore}
        sectionTitles={sectionTitles} />
      {isUserAcdAdmin ? <LeverButtonsWrapper leverStore={leverStore} /> : ''}
    </div>
  );
};

InteractableLeverWrapper.propTypes = {
  levers: PropTypes.object.isRequired,
  leverStore: PropTypes.any,
  sectionTitles: PropTypes.array.isRequired
};

export default InteractableLeverWrapper;
