// client/app/admin/components/CaseflowDistribution/InteractableLeverWrapper.js

import React from 'react';
import InteractableLever from './InteractableLever';
import PropTypes from 'prop-types';

const InteractableLeverWrapper = ({ InteractableLevers, levers }) => {
  return (
    <div>
      <h3>Active Levers</h3>
      {InteractableLevers.map((leverItem) => {
        const lever = levers.find((l) => l.item === leverItem);
        return lever ? (
          <InteractableLever key={lever.item} lever={lever} />
        ) : null;
      })}
    </div>
  );
};

InteractableLeverWrapper.propTypes = {
  InteractableLevers: PropTypes.array.isRequired,
  levers: PropTypes.array.isRequired,
};

export default InteractableLeverWrapper;
