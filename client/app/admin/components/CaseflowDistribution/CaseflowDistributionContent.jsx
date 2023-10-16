// client/app/admin/components/CaseflowDistribution/CaseflowDistributionContent.js

import React from 'react';
import InteractableLeverWrapper from './InteractableLeverWrapper';
import StaticLeverWrapper from './StaticLeversWrapper';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

const CaseflowDistributionContent = ({ levers, activeLevers, saveChanges }) => {
  return (
    <div>
      <h2>Caseflow Distribution Content</h2>
      <InteractableLeverWrapper levers={levers} activeLevers={activeLevers} />
      <StaticLeverWrapper levers={levers} activeLevers={inactiveLevers} />
      {/* cancel and save button component */}
      {/* Other content */}
    </div>
  );
};

CaseflowDistributionContent.propTypes = {
  levers: PropTypes.array.isRequired,
  activeLevers: PropTypes.array.isRequired,
  inactiveLevers: PropTypes.array.isRequired,
  saveChanges: PropTypes.func.isRequired,
};

// ...

export default connect(mapStateToProps, mapDispatchToProps)(CaseflowDistributionContent);