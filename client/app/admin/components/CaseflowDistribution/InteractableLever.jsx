// client/app/admin/components/CaseflowDistribution/InteractableLever.js

import React from 'react';
import PropTypes from 'prop-types';

const InteractableLever = ({ lever }) => {
  return (
    <div className="active-lever">
      <strong>{lever.title}</strong>
      <p>{lever.description}</p>
      <div>
        <input type="number" value={lever.newValue} />
        <span>{lever.unit}</span>
      </div>
    </div>
  );
};

InteractableLever.propTypes = {
  lever: PropTypes.shape({
    title: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    newValue: PropTypes.number.isRequired,
    unit: PropTypes.string.isRequired,
  }).isRequired,
};

export default InteractableLever;