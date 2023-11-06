import React from 'react';
import PropTypes from 'prop-types';

const CaseflowDistributionContent = ({param1}) => {
  return (
    <div className="cf-app-segment cf-app-segment--alt">
      <div> {/*Wrapper*/}
        <h1>Hello World</h1>
      </div>
    </div>
  );
};

CaseflowDistributionContent.propTypes = {
  param1: PropTypes.any,
};

export default CaseflowDistributionContent;
