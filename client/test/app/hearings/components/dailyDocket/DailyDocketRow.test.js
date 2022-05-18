import React from 'react';
import { render } from '@testing-library/react';
import { axe } from 'jest-axe';
import { BrowserRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import { dailyDocketReducer } from '../../../../data/hearings/dailyDocket/reducer/dailyDocketReducer';
import {
  dailyDokcetPropsHearingIsVirtual,
  dailyDokcetPropsHearingNotVirtual } from '../../../../data/hearings/dailyDocket/dailyDocketProps';
import DailyDocketRow from '../../../../../app/hearings/components/dailyDocket/DailyDocketRow';
import { shallow } from 'enzyme';

let store;

describe('DailyDocketRow', () => {
  beforeEach(() => {
    store = createStore(dailyDocketReducer);
  });

  it('renders correctly for non virtual', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDokcetPropsHearingNotVirtual} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });

  it('renders correctly for virtual', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDokcetPropsHearingIsVirtual} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });

  it('Non Virtual passes a11y testing', async () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDokcetPropsHearingNotVirtual} />
        </Router>
      </Provider>
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('Virtual passes a11y testing', async () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDokcetPropsHearingIsVirtual} />
        </Router>
      </Provider>
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});

describe('Test Conference Link Button', () => {
  it('Test click event', () => {
    const conferenceLink = jest.fn();
    const button = shallow((<button onClick={conferenceLink}>Connect to Recording System</button>));

    button.find('button').simulate('click');
    expect(conferenceLink.mock.calls.length).toEqual(1);
  });
});
