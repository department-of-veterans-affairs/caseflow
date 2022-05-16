import React from 'react';
import { render } from '@testing-library/react';
import { axe } from 'jest-axe';
import { BrowserRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import { dailyDocketReducer } from '../../../../data/hearings/dailyDocket/reducer/dailyDocketReducer';
import { dailyDokcetProps } from '../../../../data/hearings/dailyDocket/dailyDocketProps';
import DailyDocketRow from '../../../../../app/hearings/components/dailyDocket/DailyDocketRow';
import { shallow } from 'enzyme';

let store;

describe('DailyDocketRow', () => {
  beforeEach(() => {
    store = createStore(dailyDocketReducer);
  });

  it('renders correctly', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDokcetProps} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
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
