import React from 'react';
import { render, screen } from '@testing-library/react';
import VhaHelp from '../../../app/help/components/VhaHelp';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import helpReducers, { initialState } from '../../../app/help/helpApiSlice';
import { VHA_MEMBERSHIP_REQUEST_FORM_SUBMIT_SUCCESS_MESSAGE } from '../../../COPY';
import { sprintf } from 'sprintf-js';

describe('VhaHelp', () => {

  const setup = (state = { userLoggedIn: true }) => {
    const helpState = { ...initialState, ...state };
    const store = createStore(helpReducers, { help: { ...helpState } });

    return render(<Provider store={store}>
      <VhaHelp />
    </Provider>);
  };

  it('renders the help page', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('renders the help page for a user that is not logged in', () => {
    const { container } = setup({ userLoggedIn: false });

    expect(container).toMatchSnapshot();
  });

  it('renders the success banner when redux store contains a message', async () => {
    const messageText = sprintf(VHA_MEMBERSHIP_REQUEST_FORM_SUBMIT_SUCCESS_MESSAGE, 'VHA group');
    const successMessageState = {
      messages: {
        success: messageText,
        error: null,
      }
    };

    setup(successMessageState);

    expect(screen.getByText(messageText)).toBeVisible();
  });
});
