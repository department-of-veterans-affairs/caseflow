import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import VhaMembershipRequestForm from '../../../../app/help/components/VhaMembershipRequestForm';
import helpReducers, { initialState } from '../../../../app/help/helpApiSlice';
import COPY from '../../../../COPY';

describe('VhaMembershipRequestForm', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = (state = {}) => {
    const helpState = { ...initialState, ...state };
    const store = createStore(helpReducers, { help: { ...helpState } });

    return render(<Provider store={store}>
      <VhaMembershipRequestForm />
    </Provider>);
  };

  it('renders the default state with the feature toggle disabled correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('renders the default state with the feature toggle enabled correctly', () => {
    const { container } = setup({ featureToggles: { programOfficeTeamManagement: true } });

    expect(container).toMatchSnapshot();
  });

  it('should enable the submit button when the VHA checkbox is checked', () => {
    setup();

    expect(screen.getByLabelText('VHA')).not.toBeChecked();
    expect(screen.getByText('Submit').disabled).toBe(true);

    userEvent.click(screen.getByLabelText('VHA'));

    expect(screen.getByLabelText('VHA')).toBeChecked();

    expect(screen.getByText('Submit').disabled).toBe(false);

  });

  it('should enable the submit and display the vha access note when VHA CAMO is checked', () => {
    setup();

    expect(screen.getByText('Submit').disabled).toBe(true);
    userEvent.click(screen.getByLabelText('VHA CAMO'));
    expect(screen.getByText('Submit').disabled).toBe(false);
    expect(screen.getByText(COPY.VHA_MEMBERSHIP_REQUEST_AUTOMATIC_VHA_ACCESS_NOTE)).toBeVisible();
  });

  it('should enable the submit and display the vha access note when a program office checkbox is checked', () => {
    setup({ featureToggles: { programOfficeTeamManagement: true } });

    expect(screen.getByText('Submit').disabled).toBe(true);
    userEvent.click(screen.getByLabelText('Veteran and Family Members Program'));
    expect(screen.getByText('Submit').disabled).toBe(false);
    expect(screen.getByText(COPY.VHA_MEMBERSHIP_REQUEST_AUTOMATIC_VHA_ACCESS_NOTE)).toBeVisible();
  });
});
