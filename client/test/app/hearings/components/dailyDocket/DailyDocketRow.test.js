import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import { BrowserRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import { dailyDocketReducer } from '../../../../data/hearings/dailyDocket/reducer/dailyDocketReducer';
import {
  dailyDocketPropsHearingIsVirtual,
  dailyDocketPropsHearingNotVirtualVSOUser,
  dailyDocketPropsHearingNotVirtualJudgeUser,
  dailyDocketPropsHearingNotVirtualCoordinatorUser,
  dailyDocketPropsHearingNotVirtualAttorneyUser,
  dailyDocketPropsHearingNotVirtualDVCUser,
  dailyDocketPropsHearingNotVirtualTranscriberUser,
  dailyDocketPropsConferenceLinkError } from '../../../../data/hearings/dailyDocket/dailyDocketProps';
import DailyDocketRow from '../../../../../app/hearings/components/dailyDocket/DailyDocketRow';
import { shallow } from 'enzyme';
import DailyDocketContainer from '../../../../../app/hearings/containers/DailyDocketContainer';

let store;

describe('DailyDocketRow', () => {
  beforeEach(() => {
    store = createStore(dailyDocketReducer);
  });

  it('renders correctly for virtual', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDocketPropsHearingIsVirtual} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });

  it('renders correctly for non virtual, judge', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDocketPropsHearingNotVirtualJudgeUser} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });

  it('connect to recording renders correctly', () => {
    render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDocketPropsHearingNotVirtualJudgeUser} />
        </Router>
      </Provider>
    );

    expect(screen.getByRole('button', { class: 'usa-button-secondary usa-button', name: 'Connect to Recording System' })).toBeInTheDocument();
  });

  it('renders correctly for non virtual, attorney', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDocketPropsHearingNotVirtualAttorneyUser} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });

  it('renders correctly for non virtual, hearing cooridnator', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDocketPropsHearingNotVirtualCoordinatorUser} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });

  it('renders correctly for non virtual, VSO ', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDocketPropsHearingNotVirtualVSOUser} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });

  it('renders correctly for non virtual, DVC ', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDocketPropsHearingNotVirtualDVCUser} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });

  it('renders correctly for non virtual, Transcriber ', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDocketPropsHearingNotVirtualTranscriberUser} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });

  it('renders banner correctly for conference link error', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketContainer {...dailyDocketPropsConferenceLinkError} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });

  it('Conference Link Error passes a11y testing', async () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketContainer {...dailyDocketPropsConferenceLinkError} />
        </Router>
      </Provider>
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('Non Virtual passes a11y testing, as judge', async () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDocketPropsHearingNotVirtualJudgeUser} />
        </Router>
      </Provider>
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('Non Virtual passes a11y testing, as VSO', async () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDocketPropsHearingNotVirtualVSOUser} />
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
          <DailyDocketRow {...dailyDocketPropsHearingIsVirtual} />
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
