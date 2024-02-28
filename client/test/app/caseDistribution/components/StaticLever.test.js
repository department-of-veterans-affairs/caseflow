import React from 'react';
import { render } from '@testing-library/react';
import StaticLever from 'app/caseDistribution/components/StaticLever';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { levers, unknownDataTypeStaticLevers } from '../../../data/adminCaseDistributionLevers';

describe('Static Lever', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let staticNumber = levers.filter((lever) => (lever.lever_group === 'static' && lever.data_type === 'number'));
  let staticBoolean = levers.filter((lever) => lever.lever_group === 'static' && lever.data_type === 'boolean');
  let staticRadio = levers.filter((lever) => lever.lever_group === 'static' && lever.data_type === 'radio');
  let staticCombination = levers.filter((lever) => lever.lever_group === 'static' && lever.data_type === 'combination');
  let staticNoType = unknownDataTypeStaticLevers;

  it('renders the Static Lever with standard number value', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        {staticNumber.map((lever) => (
          <StaticLever key={lever.item} lever={lever} />
        ))}
      </Provider>
    );

    for (const lever of staticNumber) {

      expect(document.getElementById(`${lever.item}-description`)).toHaveTextContent(lever.description);
      expect(document.getElementById(`${lever.item}-value`)).toHaveTextContent(lever.value);
      expect(document.getElementById(`${lever.item}-unit`)).toHaveTextContent(lever.unit);
    }
  });

  it('renders the Static Lever with boolean value', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        {staticBoolean.map((lever) => (
          <StaticLever key={lever.item} lever={lever} />
        ))}
      </Provider>
    );

    for (const lever of staticBoolean) {
      let formattedValue = lever.value.toString();

      formattedValue = formattedValue.charAt(0).toUpperCase() + formattedValue.slice(1);

      expect(document.getElementById(`${lever.item}-description`)).toHaveTextContent(lever.description);
      expect(document.getElementById(`${lever.item}-value`)).toHaveTextContent(formattedValue);
    }
  });

  it('renders the Static Lever with Radio value', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        {staticRadio.map((lever) => (
          <StaticLever key={lever.item} lever={lever} />
        ))}
      </Provider>
    );

    for (const lever of staticRadio) {
      let selectedOption = lever.options.find((option) => lever.value === option.item);

      expect(document.getElementById(`${lever.item}-description`)).toHaveTextContent(lever.description);
      expect(document.getElementById(`${lever.item}-value`)).toHaveTextContent(selectedOption.text);
      expect(document.getElementById(`${lever.item}-unit`)).toHaveTextContent(lever.unit);
    }
  });

  it('renders the Static Lever with Combination value', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        {staticCombination.map((lever) => (
          <StaticLever key={lever.item} lever={lever} />
        ))}
      </Provider>
    );

    for (const lever of staticCombination) {
      expect(document.getElementById(`${lever.item}-description`)).toHaveTextContent(lever.description);
      expect(document.getElementById(`${lever.item}-value`)).toHaveTextContent(lever.value);
      expect(document.getElementById(`${lever.item}-unit`)).toHaveTextContent(lever.unit);
    }
  });

  it('renders the Static Lever with uknown group lever value', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        {staticNoType.map((lever) => (
          <StaticLever key={lever.item} lever={lever} />
        ))}
      </Provider>
    );

    for (const lever of staticNoType) {
      expect(document.getElementById(`${lever.item}-description`)).toHaveTextContent(lever.description);
      expect(document.getElementById(`${lever.item}-value`)).toHaveTextContent('test-unit-unknown-dt-static');
    }
  });
});
