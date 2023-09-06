import React from 'react';
import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';
import AddDecisionDateModal from './AddDecisionDateModal';
import mockData from './mockData';

const ReduxDecorator = (Story) => (
  <ReduxBase reducer={reducer} initialState={generateInitialState()}>
    <Story />
  </ReduxBase>
);

export default {
  component: AddDecisionDateModal,
  decorators: [ReduxDecorator],
  title: 'Intake/Edit Issues/Add Decision Date Modal',
};

export const Basic = () => {
  const { closeHandler, currentIssue, index } = mockData;

  return (
    <AddDecisionDateModal closeHandler={closeHandler} currentIssue={currentIssue} index={index} />
  );
};
