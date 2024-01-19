import React from 'react';
import { render, screen } from '@testing-library/react';
import StaticLever from 'app/caseDistribution/components/StaticLever';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import ACD_LEVERS from '../../../../constants/ACD_LEVERS';

describe('Static Lever', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  let leversNumber = [
    {
      item: 'leverStatic',
      title: 'Minimum Legacy Proportion',
      description: 'Sets the minimum proportion of legacy appeals that will be distributed.',
      data_type: ACD_LEVERS.data_types.number,
      value: 0.2,
      unit: '%',
      is_toggle_active: false,
      is_disabled_in_ui: true,
      min_value: 0,
      max_value: 1,
      algorithms_used: [ACD_LEVERS.algorithms.proportion],
      lever_group: ACD_LEVERS.lever_groups.static,
      lever_group_order: 1001
    },
  ];

  let leversBoolean = [
    {
      item: 'leverBooleanStatic',
      title: 'Title Lever Boolean',
      description: 'Description for boolean static lever',
      data_type: ACD_LEVERS.data_types.boolean,
      value: true,
      unit: '',
      is_toggle_active: false,
      is_disabled_in_ui: true,
      min_value: 0,
      max_value: 1,
      algorithms_used: [],
      lever_group: ACD_LEVERS.lever_groups.static,
      lever_group_order: 1002
    },
  ];

  let leversRadio = [
    {
      item: 'leverRadioStatic',
      title: 'Title Lever Radio',
      description: 'Description for radio static lever',
      data_type: ACD_LEVERS.data_types.radio,
      value: 'option_value_1',
      unit: '',
      options: [
        {
          value: 'option_value_1',
          text: 'Text_Output_Option_1'
        },
        {
          value: 'option_value_2',
          text: 'Text_Output_Option_2'
        }
      ],
      is_toggle_active: false,
      is_disabled_in_ui: true,
      min_value: 0,
      max_value: 1,
      algorithms_used: [],
      lever_group: ACD_LEVERS.lever_groups.static,
      lever_group_order: 1003
    },
  ];

  let leversCombination = [
    {
      item: 'leverCombinationStatic',
      title: 'Title Lever Combination',
      description: 'Description for combination static lever',
      data_type: ACD_LEVERS.data_types.combination,
      value: 365,
      unit: 'days',
      options: [
        {
          item: 'value',
          data_type: ACD_LEVERS.data_types.boolean,
          value: true,
          text: 'This feature is turned on or off',
          unit: ''
        },
      ],
      is_toggle_active: false,
      is_disabled_in_ui: true,
      min_value: 0,
      max_value: 1,
      algorithms_used: [],
      lever_group: ACD_LEVERS.lever_groups.static,
      lever_group_order: 1004
    },
  ];

  let leverUnknownGroup = [
    {
      item: 'leverStaticUnknown',
      title: 'Title Lever Unknown',
      description: 'Static Lever Unknown Description',
      data_type: "testDataType",
      value: 'test Value',
      unit: 'test Unit',
      is_toggle_active: false,
      is_disabled_in_ui: true,
      min_value: 0,
      max_value: 1,
      algorithms_used: [],
      lever_group: ACD_LEVERS.lever_groups.static,
      lever_group_order: 1005
    },
  ];

  it('renders the Static Lever with standard number value', () => {

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    render(
      <Provider store={store}>
        {leversNumber.map((lever) => (
          <StaticLever key={lever.item} lever={lever} />
        ))}
      </Provider>
    );

    expect(screen.getByText('Sets the minimum proportion of legacy appeals that will be distributed.')).
      toBeInTheDocument();
    expect(screen.getByText('20')).toBeInTheDocument();
  });

  it('renders the Static Lever with boolean value', () => {

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    render(
      <Provider store={store}>
        {leversBoolean.map((lever) => (
          <StaticLever key={lever.item} lever={lever} />
        ))}
      </Provider>
    );

    expect(screen.getByText('Description for boolean static lever')).toBeInTheDocument();
    expect(screen.getByText('True')).toBeInTheDocument();
  });

  it('renders the Static Lever with Radio value', () => {

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    render(
      <Provider store={store}>
        {leversRadio.map((lever) => (
          <StaticLever key={lever.item} lever={lever} />
        ))}
      </Provider>
    );

    expect(screen.getByText('Description for radio static lever')).toBeInTheDocument();
    expect(screen.getByText('Text_Output_Option_1')).toBeInTheDocument();
  });

  it('renders the Static Lever with Combination value', () => {

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    render(
      <Provider store={store}>
        {leversCombination.map((lever) => (
          <StaticLever key={lever.item} lever={lever} />
        ))}
      </Provider>
    );

    expect(screen.getByText('Description for combination static lever')).toBeInTheDocument();
    expect(screen.getByText('365')).toBeInTheDocument();
    expect(screen.getByText('days')).toBeInTheDocument();
  });

  it('renders the Static Lever with uknown group lever value', () => {

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    render(
      <Provider store={store}>
        {leverUnknownGroup.map((lever) => (
          <StaticLever key={lever.item} lever={lever} />
        ))}
      </Provider>
    );

    expect(screen.getByText('Static Lever Unknown Description')).toBeInTheDocument();
  });
});
