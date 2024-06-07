import React from 'react';
import ScenarioSeeds from './ScenarioSeeds';
import CustomSeeds from './CustomSeeds';

const TestSeedsWrapper = () => {
  return (
    <div>
      <CustomSeeds />
      <ScenarioSeeds />
    </div>
  );
};

export default TestSeedsWrapper;
