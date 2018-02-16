import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import LoadingDataDisplay from '../../../app/components/LoadingDataDisplay';

describe('LoadingDataDisplay', () => {
  it('shows loading state initially', () => {
    // eslint-disable-next-line no-empty-function
    const createEternalPromise = () => new Promise(() => {});
    const loadingScreenMessage = 'Loading screen message';
    const wrapper = mount(
      <LoadingDataDisplay
        createLoadPromise={createEternalPromise}
        loadingComponentProps={{
          message: loadingScreenMessage
        }}
      >
        <p>Request succeeded</p>
      </LoadingDataDisplay>
    );

    expect(wrapper.text()).to.include(loadingScreenMessage);
  });

  const wait = (timeoutMs) => new Promise((resolve) => setTimeout(resolve, timeoutMs));

  it('shows success component', () => {
    const createFailingPromise = () => Promise.resolve();
    const requestSucceededMessage = 'Request succeeded';
    const wrapper = mount(
      <LoadingDataDisplay
        createLoadPromise={createFailingPromise}
        loadingComponentProps={{
          message: 'loading message'
        }}
        failStatusMessageChildren={<p>Fail message</p>}
      >
        <p>{requestSucceededMessage}</p>
      </LoadingDataDisplay>
    );

    return wait().then(() => {
      expect(wrapper.text()).to.include(requestSucceededMessage);
    });
  });

  it('shows fail component', () => {
    const createFailingPromise = () => Promise.reject({ status: 500 });
    const wrapper = mount(
      <LoadingDataDisplay
        createLoadPromise={createFailingPromise}
        loadingComponentProps={{
          message: 'loading message'
        }}
        failStatusMessageChildren={<p>Fail message</p>}
      >
        <p>Request succeeded</p>
      </LoadingDataDisplay>
    );

    return wait().then(() => {
      expect(wrapper.text()).to.include('Fail message');
    });
  });

  it('slow loading state', function() {
    const SLOW_TIMEOUT_MS = 4000;

    this.timeout(SLOW_TIMEOUT_MS * 2);
    const createSlowPromise = () => wait(SLOW_TIMEOUT_MS);
    const wrapper = mount(
      <LoadingDataDisplay
        createLoadPromise={createSlowPromise}
        slowLoadThresholdMs={SLOW_TIMEOUT_MS / 10}
        loadingComponentProps={{
          message: 'loading message'
        }}
      >
        <p>Request succeeded</p>
      </LoadingDataDisplay>
    );

    return wait(SLOW_TIMEOUT_MS / 2).then(() => {
      expect(wrapper.text()).to.include('Loading is taking longer than usual...');
    });
  });

  it('timeout state', function() {
    const TIMEOUT_MS = 4000;

    this.timeout(TIMEOUT_MS * 2);
    const createSlowPromise = () => wait(TIMEOUT_MS);
    const wrapper = mount(
      <LoadingDataDisplay
        createLoadPromise={createSlowPromise}
        slowLoadThresholdMs={TIMEOUT_MS / 20}
        timeoutMs={TIMEOUT_MS / 10}
        loadingComponentProps={{
          message: 'loading message'
        }}
        failStatusMessageChildren={<p>Fail message</p>}
      >
        <p>Request succeeded</p>
      </LoadingDataDisplay>
    );

    return wait(TIMEOUT_MS / 2).then(() => {
      expect(wrapper.text()).to.include('Fail message');
    });
  });

});
