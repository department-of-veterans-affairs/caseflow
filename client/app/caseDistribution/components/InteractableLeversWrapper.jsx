import React from 'react';
import { useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import BatchSize from './BatchSize';
import DocketTimeGoals from './DocketTimeGoals';
import AffinityDays from './AffinityDays';
import LeverButtonsWrapper from './LeverButtonsWrapper';
import ExclusionTable from './ExclusionTable';
import { getUserIsAcdAdmin } from '../reducers/levers/leversSelector';

const InteractableLeverWrapper = ({ leverStore }) => {
  const theState = useSelector((state) => state);
  const isUserAcdAdmin = getUserIsAcdAdmin(theState);

  return (
    <div>
      <ExclusionTable />
      <BatchSize />
      <AffinityDays />
      <DocketTimeGoals />
      {isUserAcdAdmin ? <LeverButtonsWrapper leverStore={leverStore} /> : ''}
    </div>
  );
};

InteractableLeverWrapper.propTypes = {
  leverStore: PropTypes.any
};

export default InteractableLeverWrapper;
