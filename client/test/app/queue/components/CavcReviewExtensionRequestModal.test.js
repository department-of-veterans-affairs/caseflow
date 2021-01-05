import React from 'react';
import { mount } from 'enzyme';

import { CavcReviewExtensionRequestModalUnconnected } from 'app/queue/components/CavcReviewExtensionRequestModal';
import { SearchableDropdown } from 'app/components/SearchableDropdown';

import COPY from 'COPY';

describe('CavcReviewExtensionRequestModal', () => {
  beforeEach(() => jest.clearAllMocks());

  const onSubmit = jest.fn();
  const onCancel = jest.fn();

  const setup = (args = {}) => {
    return mount(
      <CavcReviewExtensionRequestModalUnconnected
        onCancel={onCancel}
        onSubmit={onSubmit}
        {...args}
      />
    );
  };

  const clickSubmit = (modal) => modal.find('button#Review-extension-request-button-id-1').simulate('click');
  const clickCancel = (modal) => modal.find('button#Review-extension-request-button-id-0').simulate('click');
  const selectGrant = (modal) => modal.find('#decision_grant').simulate('change', { target: { value: 'grant' } });
  const selectDeny = (modal) => modal.find('#decision_deny').simulate('change', { target: { value: 'deny' } });
  const select15DayDuration = (modal) => {
    const dropdown = modal.find(SearchableDropdown);

    // Select the first option ("15 days") and press enter
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
    dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });
  };
  const selectCustomDuration = (modal) => {
    const dropdown = modal.find(SearchableDropdown);

    // Select the last option ("custom") and press enter
    dropdown.find('Select').simulate('keyDown', { key: 'ArrowUp', keyCode: 38 });
    dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });
  };
  const populateCustomDuration = (modal, duration) => (
    modal.find('#customDuration').simulate('change', { target: { value: duration } })
  );
  const populateInstructions = (modal, instructions) => (
    modal.find('#instructions').simulate('change', { target: { value: instructions } })
  );

  it('renders correctly', async () => {
    const extensionModal = setup();

    expect(extensionModal).toMatchSnapshot();
  });

  it('shows hold duration selector only when decision is grant', () => {
    const extensionModal = setup();

    expect(extensionModal.find('input#duration').length).toBe(0);
    selectGrant(extensionModal);
    expect(extensionModal.find('input#duration').length).toBe(1);
    selectDeny(extensionModal);
    expect(extensionModal.find('input#duration').length).toBe(0);
  });

  it('shows custom hold duration selector when only decision is grant and duration is custom', () => {
    const extensionModal = setup();

    expect(extensionModal.find('input#customDuration').length).toBe(0);
    selectGrant(extensionModal);
    expect(extensionModal.find('input#customDuration').length).toBe(0);
    select15DayDuration(extensionModal);
    expect(extensionModal.find('input#customDuration').length).toBe(0);
    selectCustomDuration(extensionModal);
    expect(extensionModal.find('input#customDuration').length).toBe(1);
    select15DayDuration(extensionModal);
    expect(extensionModal.find('input#customDuration').length).toBe(0);
  });

  it('displays an error if provided', () => {
    const title = 'Error title';
    const detail = 'Error message';
    const extensionModal = setup({ error: { title, detail } });

    expect(extensionModal.find('.usa-alert-error').length).toBe(1);
    expect(extensionModal.find('.usa-alert-heading').props().children).toBe(title);
    expect(extensionModal.find('.usa-alert-text').props().children).toBe(detail);
  });

  it('calls onSubmit with selected values when "Confirm" is pressed and form is valid', () => {
    const extensionModal = setup();

    selectDeny(extensionModal);
    populateInstructions(extensionModal, 'instructions');
    clickSubmit(extensionModal);

    expect(onSubmit).toHaveBeenCalledWith('deny', 'instructions', null);

    selectGrant(extensionModal);
    select15DayDuration(extensionModal);
    populateInstructions(extensionModal, 'new instructions');
    clickSubmit(extensionModal);

    expect(onSubmit).toHaveBeenCalledWith('grant', 'new instructions', 15);

    selectCustomDuration(extensionModal);
    populateInstructions(extensionModal, 'new new instructions');
    populateCustomDuration(extensionModal, 25);
    clickSubmit(extensionModal);

    expect(onSubmit).toHaveBeenCalledWith('grant', 'new new instructions', 25);
  });

  it('calls onCancel ', () => {
    const extensionModal = setup();

    clickCancel(extensionModal);

    expect(onCancel).toHaveBeenCalled();
  });

  describe('form validations', () => {
    const errorClass = '.usa-input-error-message';

    const validationErrorShows = (modal, errorMessage) => {
      clickSubmit(modal);

      return modal.find(errorClass).findWhere((node) => node.props().children === errorMessage).length > 0;
    };

    describe('decision type validations', () => {
      const error = 'Choose one';

      it('shows error on no decision type selection', () => {
        const extensionModal = setup();

        expect(validationErrorShows(extensionModal, error)).toBeTruthy();
      });

      it('does not show error on correctly selected decision type', () => {
        const extensionModal = setup();

        selectDeny(extensionModal);

        expect(validationErrorShows(extensionModal, error)).toBeFalsy();
      });
    });

    describe('on hold duration validations', () => {
      const error = 'Choose one';

      it('shows error on no selected on hold duration', () => {
        const extensionModal = setup();

        selectGrant(extensionModal);

        expect(validationErrorShows(extensionModal, error)).toBeTruthy();
      });

      it('does not show error on selected on hold duration', () => {
        const extensionModal = setup();

        selectGrant(extensionModal);
        select15DayDuration(extensionModal);

        expect(validationErrorShows(extensionModal, error)).toBeFalsy();
      });
    });

    describe('custom on hold duration validations', () => {
      const error = COPY.COLOCATED_ACTION_PLACE_CUSTOM_HOLD_INVALID_VALUE;

      it('shows error on no selected custom hold duration', () => {
        const extensionModal = setup();

        selectGrant(extensionModal);
        selectCustomDuration(extensionModal);

        expect(validationErrorShows(extensionModal, error)).toBeTruthy();
      });

      it('shows error on selected duration less than 1', () => {
        const extensionModal = setup();

        selectGrant(extensionModal);
        selectCustomDuration(extensionModal);
        populateCustomDuration(extensionModal, -1);

        expect(validationErrorShows(extensionModal, error)).toBeTruthy();
      });

      it('does not show error on valid custom hold duration', () => {
        const extensionModal = setup();

        selectGrant(extensionModal);
        selectCustomDuration(extensionModal);
        populateCustomDuration(extensionModal, 25);

        expect(validationErrorShows(extensionModal, error)).toBeFalsy();
      });
    });

    describe('instruction validations', () => {
      const error = COPY.CAVC_INSTRUCTIONS_ERROR;

      it('shows error on no provided instructions', () => {
        const extensionModal = setup();

        expect(validationErrorShows(extensionModal, error)).toBeTruthy();
      });

      it('does not show error on provided instructions', () => {
        const extensionModal = setup();

        populateInstructions(extensionModal, 'here are some instructions');

        expect(validationErrorShows(extensionModal, error)).toBeFalsy();
      });
    });
  });
});
