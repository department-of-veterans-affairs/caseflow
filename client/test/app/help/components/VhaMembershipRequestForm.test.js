import React from 'react';
import { fireEvent, getByLabelText, getByText, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import VhaMembershipRequestForm from '../../../../app/help/components/VhaMembershipRequestForm';
import helpReducers, { initialState } from '../../../../app/help/helpApiSlice';
import { Simulate } from 'react-dom/test-utils';

describe('VhaMembershipRequestForm', () => {
  beforeEach(() => {
    // Nothing yet.
  });

  const setup = () => {
    const store = createStore(helpReducers, { ...initialState });

    return render(<Provider store={store}>
      <VhaMembershipRequestForm />
    </Provider>);
  };

  it('renders the default state correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  // it('should enable the submit button when a checkbox is selected', async () => {
  //   const { container } = setup();

  //   // const vhaCheckbox = screen.getByLabelText('VHA');
  //   // const vhaCheckbox = container.querySelector('input[name="vhaAccess"]');
  //   // const checkboxLabel = screen.getByText(/checkbox/i, { selector: 'VHA' });
  //   const submitButton = screen.getByText('Submit');
  //   const vhaCheckbox = getByLabelText(container, 'VHA');

  //   const label = screen.getByLabelText('VHA', { selector: 'input' });

  //   // const vhaCheckbox = screen.getByRole('checkbox', { name: 'VHA' });
  //   // const vhaCheckbox = screen.getByRole('checkbox');

  //   expect(submitButton.disabled).toBe(true);
  //   // vhaCheckbox.checked = true;
  //   // fireEvent.click(vhaCheckbox);
  //   // fireEvent.click(label);
  //   // fireEvent.click(vhaCheckbox);
  //   fireEvent(vhaCheckbox, new MouseEvent('click', {
  //     bubbles: true,
  //     cancelable: true,
  //   }));
  //   // await waitFor();
  //   // userEvent.click(vhaCheckbox);

  //   // const vhaCheckbox =
  //   // fireEvent.click(vhaCheckbox);
  //   // fireEvent(vhaCheckbox, 'onValueChange', { nativeEvent: {} });

  //   // vhaCheckbox.click;

  //   // expect(vhaCheckbox.checked).toBe(true);
  //   await waitFor(() => expect(submitButton.disabled).toBe(false));

  // });

});
