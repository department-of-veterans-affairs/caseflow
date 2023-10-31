// client/app/admin/components/CaseflowDistribution/StaticLeverWrapper.js

import React from 'react';
import StaticLever from './StaticLever';
import PropTypes from 'prop-types';

const StaticLeverWrapper = ({ InteractableLevers, levers }) => {
  return (
    <div>
      <h3>Inactive Levers</h3>
      {InteractableLevers.map((leverItem) => {
        const lever = levers.find((l) => l.item === leverItem);
        return lever ? (
          <StaticLever key={lever.item} lever={lever} />
        ) : null;
      })}
    </div>
  );
};

StaticLeverWrapper.propTypes = {
  StaticLevers: PropTypes.array.isRequired,
  levers: PropTypes.array.isRequired,
};

export default StaticLeverWrapper;
