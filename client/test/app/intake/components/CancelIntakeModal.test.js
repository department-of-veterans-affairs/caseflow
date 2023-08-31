import React from 'react';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import userEvent from '@testing-library/user-event';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';
import CancelIntakeModal from 'app/intake/components/CancelIntakeModal';
import { CANCELLATION_REASONS } from 'app/intake/constants';

jest.mock('redux', () => ({
  ...jest.requireActual('redux'),
  bindActionCreators: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));

describe('CancelIntakeModal', () => {
  const defaultProps = {
    closeHandler: () => {},
    intakeId: '123 change?',
    clearClaimant: jest.fn().mockImplementation(() => Promise.resolve(true)),
    clearPoa: jest.fn().mockImplementation(() => Promise.resolve(true)),
    submitCancel: jest.fn().mockImplementation(() => Promise.resolve(true))
  };
  const buttonText = 'Cancel intake';

  afterEach(() => {
    jest.clearAllMocks();
  });

  const store = createStore(rootReducer, applyMiddleware(thunk));

  const setup = (props) =>
    render(
      <Provider store={store}>
        <CancelIntakeModal
          {...props}
        />
      </Provider>
    );

  it('renders correctly', () => {
    const modal = setup(defaultProps);

    expect(modal).toMatchSnapshot();
  });

  it('displays cancellation options', () => {
    const modal = setup(defaultProps);

    Object.values(CANCELLATION_REASONS).map((reason) => (
      expect(modal.getByText(reason.name)).toBeInTheDocument()
    ));
  });

  it('should show other reason input when other is selected', async () => {
    const modal = setup(defaultProps);

    await userEvent.click(screen.getByText('Other'));

    expect(modal.getByText('Tell us more about your situation.')).toBeInTheDocument();
  });

  describe('cancel button', () => {
    it('is disabled until "Other" is selected and the text input is filled out', async () => {
      const modal = setup(defaultProps);

      expect(modal.getByText(buttonText)).toBeDisabled();

      await userEvent.click(modal.getByText('Other'));

      expect(modal.getByText('Tell us more about your situation.')).toBeInTheDocument();
      expect(modal.getByText(buttonText)).toBeDisabled();

      await userEvent.type(modal.getByRole('textbox'), 'Test');

      expect(modal.getByText(buttonText)).not.toBeDisabled();
    });

    it('is disabled until value (that is not "Other") is selected', async () => {
      const modal = setup(defaultProps);

      expect(modal.getByText(buttonText)).toBeDisabled();

      await userEvent.click(modal.getByText('System error'));
      expect(modal.getByText(buttonText)).not.toBeDisabled();
    });
  });

  it('should call the appropiate functions when Cancel intake is clicked', async () => {
    const modal = setup(defaultProps);

    await userEvent.click(modal.getByText('System error'));
    expect(modal.getByText(buttonText)).not.toBeDisabled();

    await userEvent.click(modal.getByText('Cancel intake'));
    expect(defaultProps.clearClaimant).toHaveBeenCalled();
    expect(defaultProps.clearPoa).toHaveBeenCalled();
    expect(defaultProps.submitCancel).toHaveBeenCalled();
  });
});
