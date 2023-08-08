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
  title: 'Intake/Edit Issues/Add Decision Date Modal',
  component: AddDecisionDateModal,
  decorators: [ReduxDecorator],
};

export const Basic = () => {
  const { closeHandler, currentIssue, index } = mockData;

  return (
    <AddDecisionDateModal closeHandler={closeHandler} currentIssue={currentIssue} index={index} />
  );
};
