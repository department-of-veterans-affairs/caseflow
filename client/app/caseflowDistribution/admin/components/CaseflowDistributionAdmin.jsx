import React, { useState, useEffect } from 'react';
import { bindActionCreators } from 'redux';
import { connect, useSelector } from 'react-redux';

export const CaseflowDistributionAdmin = (props) => {
  const testRedux = useSelector((state) => state.caseflowDistribution);

  return (
    <div>Hello world!</div>
  );
};

export default connect()(CaseflowDistributionAdmin);
