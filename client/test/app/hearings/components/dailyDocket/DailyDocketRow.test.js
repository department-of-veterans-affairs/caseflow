import React from 'react';
import { screen, fireEvent, render } from '@testing-library/react';
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
import DailyDocketContainer from '../../../../../app/hearings/containers/DailyDocketContainer';

jest.mock('app/util/ApiUtil', () => ({
  convertToCamelCase: jest.fn(obj => obj),
  get: jest.fn().mockResolvedValue({})
  }));

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
  store = createStore(dailyDocketReducer);
  it('Test click event', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow
          {...dailyDocketPropsHearingNotVirtualJudgeUser}
          />
        </Router>
      </Provider>
    );

    const button = screen.getByRole('button', { name: 'Connect to Recording System' })
    expect(button).toBeInTheDocument();

    const mockOpen = jest.fn();
    const mockFocus = jest.fn();
    window.open = mockOpen;
    mockOpen.mockReturnValue({ focus: mockFocus });

    fireEvent.click(button);

    // Check if window.open was called with the correct arguments
    expect(mockOpen).toHaveBeenCalledWith(dailyDocketPropsHearingIsVirtual.conferenceLink.hostLink, 'Recording Session');
    expect(mockFocus).toHaveBeenCalled();
  });
});
