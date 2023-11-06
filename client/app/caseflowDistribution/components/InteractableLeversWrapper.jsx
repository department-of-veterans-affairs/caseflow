import React from 'react';
import PropTypes from 'prop-types';
import BatchSize from './BatchSize';
import DocketTimeGoals from './DocketTimeGoals';
import AffinityDays from './AffinityDays';
import styles from './InteractableLevers.module.scss';

const InteractableLeverWrapper = ({ levers }) => {

  const batchSizeLevers = levers.filter((lever) => {
    return lever.data_type === "number";
  });

  const docketLevers = levers.filter((lever) => {
    return lever.data_type === "combination";
  });

  const affinityLevers = levers.filter((lever) => {
    return lever.data_type === "radio";
  });

  return (
    <div className={styles.leverContainer}>
      <div className={styles.leverContent}>
        <div className={styles.leverHead}>
        <div className={styles.leverH2}>Active Data Elements</div>
          <p>You may make changes to the Case Distribution algorithm values based on the data elements below. Changes will be applied to the next scheduled case distribution event unless subsequent confirmed changes are made to the same variable.</p>
        </div>
      </div>
      <BatchSize batchSizeLevers={batchSizeLevers} />
      <AffinityDays affinityLevers={affinityLevers} />
      <DocketTimeGoals docketLevers={docketLevers} />
    </div>
  );
};

InteractableLeverWrapper.propTypes = {
  levers: PropTypes.array.isRequired,
};

export default InteractableLeverWrapper;
