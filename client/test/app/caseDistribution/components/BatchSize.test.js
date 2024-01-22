import React from 'react';
import { render } from '@testing-library/react';
import BatchSize from 'app/caseDistribution/components/BatchSize';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { levers, outOfBoundsBatchLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers } from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';
import sinon from 'sinon';

describe('Batch Size Lever', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let batchSizeLevers = levers.filter((lever) => (lever.lever_group === 'batch'));

  it('renders the Batch Size Levers', () => {
    const store = getStore();

    let testLevers = {
      batch: batchSizeLevers,
    };

    // Load all batch size levers
    store.dispatch(loadLevers(testLevers));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );

    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(batchSizeLevers[0].title);
    expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(batchSizeLevers[0].description);
    expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(batchSizeLevers[0].value);
  });

  it('responds to bad change with error', () => {
    const event = { target: { value: 2 } };

    const store = getStore();

    let testLevers = {
      batch: outOfBoundsBatchLevers,
    };

    store.dispatch(loadLevers(testLevers));

    let wrapper = mount(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );

    wrapper.update();

    console.debug(wrapper.debug());

    wrapper.find('.lever-active').simulate('change', event);

    console.debug(wrapper.debug());
    // expect(handleChangeSpy.calledOnce).toBeCalled();
    expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(outOfBoundsBatchLevers[0].value);
  });
});

