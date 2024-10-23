import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';

import { CavcReviewExtensionRequestModalUnconnected } from 'app/queue/components/CavcReviewExtensionRequestModal';

import COPY from 'COPY';

describe('CavcReviewExtensionRequestModal', () => {
  beforeEach(() => jest.clearAllMocks());

  const onSubmit = jest.fn();
  const onCancel = jest.fn();

  const setup = (args = {}) => {
    return render(
      <CavcReviewExtensionRequestModalUnconnected
        onCancel={onCancel}
        onSubmit={onSubmit}
        {...args}
      />
    );
  };
  function clickGrant(screen) {
    const grantRadio = screen.getByRole('radio', { name: 'Grant' });
    fireEvent.click(grantRadio);
  }

  function clickDeny(screen) {
    const denyRadio = screen.getByRole('radio', { name: 'Deny' });
    fireEvent.click(denyRadio);
  }

  function clickConfirm(screen) {
    const confirmButton = screen.getByRole('button', { name: 'Confirm' });
    fireEvent.click(confirmButton);
  }

  function clickCancel(screen) {
    const cancelButton = screen.getByRole('button', { name: 'Cancel' });
    fireEvent.click(cancelButton);
  }

  function select15DayDuration(screen) {
    const holdDurationDropdown = screen.getByRole('combobox', { name: 'Select number of days' });
    fireEvent.keyDown(holdDurationDropdown, { key: 'ArrowDown' });
    fireEvent.keyDown(holdDurationDropdown, { key: 'Enter' });
    expect(screen.getByText('15 days')).toBeInTheDocument();
  }

  function selectCustomDuration(screen) {
    const holdDurationDropdown = screen.getByRole('combobox', { name: 'Select number of days' });
    fireEvent.keyDown(holdDurationDropdown, { key: 'ArrowUp' });
    fireEvent.keyDown(holdDurationDropdown, { key: 'Enter' });
    expect(screen.getByText('Custom')).toBeInTheDocument();
    expect(screen.getByText(COPY.COLOCATED_ACTION_PLACE_CUSTOM_HOLD_COPY)).toBeInTheDocument();
  }

  function populateInstructions(screen, instructions) {
    const instructionsField = screen.getByRole('textbox', { name: 'Provide instructions and context for this action' });
    fireEvent.change(instructionsField, { target: { value: instructions } });
  }

  function populateCustomDuration(screen, duration) {
    const customDurationField = screen.getByRole('spinbutton', { name: 'Enter a custom number of days for the hold' });
    fireEvent.change(customDurationField, { target: { value: duration } });
  }

  it('renders correctly', () => {
    const {asFragment} = setup();

    expect(asFragment()).toMatchSnapshot();
  });

  it('shows hold duration selector only when decision is grant', () => {
    const {container} = setup();

    expect(container.querySelector('input#duration')).toBeNull();
    clickGrant(screen);
    expect(container.querySelector('input#duration')).not.toBeNull();
    clickDeny(screen);
    expect(container.querySelector('input#duration')).toBeNull();
  });

  it('shows custom hold duration selector when only decision is grant and duration is custom', () => {
    const {container} = setup();

    expect(container.querySelector('input#customDuration')).toBeNull();
    clickGrant(screen);
    expect(container.querySelector('input#customDuration')).toBeNull();
    select15DayDuration(screen);
    expect(container.querySelector('input#customDuration')).toBeNull();
    selectCustomDuration(screen);
    expect(container.querySelector('input#customDuration')).not.toBeNull();
    select15DayDuration(screen);
    expect(container.querySelector('input#customDuration')).toBeNull();
  });

  it('displays an error if provided', () => {
    const title = 'Error title';
    const detail = 'Error message';
    const {container} = setup({ error: { title, detail } });

    expect(container.querySelector('.usa-alert-error')).toBeInTheDocument();
    expect(screen.getByText(title)).toBeInTheDocument();
    expect(screen.getByText(detail)).toBeInTheDocument();
  });

  it('calls onSubmit with selected values when "Confirm" is pressed and form is valid', () => {
    const {container} = setup();

    clickDeny(screen);
    populateInstructions(screen, 'instructions');
    clickConfirm(screen);
    expect(onSubmit).toHaveBeenCalledWith('deny', 'instructions', null);

    clickGrant(screen);
    select15DayDuration(screen);
    populateInstructions(screen, 'new instructions');
    clickConfirm(screen);
    expect(onSubmit).toHaveBeenCalledWith('grant', 'new instructions', 15);

    selectCustomDuration(screen);
    populateInstructions(screen, 'new new instructions');
    populateCustomDuration(screen, 25);

    clickConfirm(screen);
    expect(onSubmit).toHaveBeenCalledWith('grant', 'new new instructions', 25);
  });

  it('calls onCancel ', () => {
    setup();

    clickCancel(screen);
    expect(onCancel).toHaveBeenCalled();
  });

  describe('form validations', () => {
    describe('decision type validations', () => {
      const error = 'Choose one';

      it('shows error on no decision type selection', () => {
        setup();

        clickConfirm(screen);
        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on correctly selected decision type', () => {
        setup();

        clickDeny(screen);
        expect(screen.queryByText(error)).not.toBeInTheDocument();
      });
    });

    describe('on hold duration validations', () => {
      const error = 'Choose one';

      it('shows error on no selected on hold duration', () => {
        setup();

        clickGrant(screen);
        clickConfirm(screen);
        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on selected on hold duration', () => {
        setup();

        clickGrant(screen);
        select15DayDuration(screen);
        clickConfirm(screen);
        expect(screen.queryByText(error)).not.toBeInTheDocument();
      });
    });

    describe('custom on hold duration validations', () => {
      const error = COPY.COLOCATED_ACTION_PLACE_CUSTOM_HOLD_INVALID_VALUE;

      it('shows error on no selected custom hold duration', () => {
        setup();

        clickGrant(screen);
        selectCustomDuration(screen);
        clickConfirm(screen);
        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('shows error on selected duration less than 1', () => {
        setup();

        clickGrant(screen);
        selectCustomDuration(screen);
        populateCustomDuration(screen, -1);
        clickConfirm(screen);
        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on valid custom hold duration', () => {
        setup();

        clickGrant(screen);
        selectCustomDuration(screen);
        populateCustomDuration(screen, 25);
        clickConfirm(screen);
        expect(screen.queryByText(error)).not.toBeInTheDocument();
      });
    });

    describe('instruction validations', () => {
      const error = COPY.CAVC_INSTRUCTIONS_ERROR;

      it('shows error on no provided instructions', () => {
        setup();

        clickConfirm(screen);
        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on provided instructions', () => {
        const extensionModal = setup();

        populateInstructions(extensionModal, 'here are some instructions');
        expect(screen.queryByText(error)).not.toBeInTheDocument();
      });
    });
  });
});
