import React from 'react';

import LoadingDataDisplay from './LoadingDataDisplay';

export default {
  title: 'Commons/Components/LoadingDataDisplay',
  component: LoadingDataDisplay,
  parameters: {
    controls: { expanded: true }
  },
  args: { ...LoadingDataDisplay.defaultProps }
};

const TIMEOUT_MS = 4000;
const createLoadPromise = () => new Promise(() => {});
const createFailingPromise = () => new Promise((resolve, reject) => setTimeout(() => reject({ status: 502 }), TIMEOUT_MS/10))
const createSlowPromise = () => new Promise((resolve, reject) => setTimeout(() => resolve(), TIMEOUT_MS))

const Template = (args) => {
  return <LoadingDataDisplay {...args} >
    <p>Request succeeded</p>
  </LoadingDataDisplay>
}

export const Loading = Template.bind({});
Loading.args = {
  createLoadPromise: createLoadPromise,
  loadingComponentProps: {
    spinnerColor: '#56b605',
    message: 'Loading the hearing details...'
  }
};

export const Error = Template.bind({});
Error.args = {
  ...Loading.args,
  createLoadPromise: createFailingPromise,
  failStatusMessageChildren: 'Failed to load hearing details'
}

export const Slow = Template.bind({});
Slow.args = {
  ...Loading.args,
  createLoadPromise: createSlowPromise
}
