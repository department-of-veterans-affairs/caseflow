import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import moment from 'moment';

import { queueWrapper } from 'test/data/stores/queueStore';
import { amaAppeal } from 'test/data/appeals';

import AddCavcRemandView from 'app/queue/cavc/AddCavcRemandView';
import COPY from 'COPY';

function customRender(ui, { wrapper: Wrapper, wrapperProps, ...options }) {
  if (Wrapper) {
    ui = <Wrapper {...wrapperProps}>{ui}</Wrapper>;
  }
  return render(ui, options);
}

const Wrapper = ({ children, ...props }) => {
  return queueWrapper({ children, ...props });
};

const appealId = amaAppeal.externalId;

describe('AddCavcRemandView', () => {
  const setup = ({ appealId: id, mdrToggled, reversalToggled, dismissalToggled }) => {
    return customRender(
      <AddCavcRemandView appealId={id} />,
      {
        wrapper: Wrapper,
        wrapperProps: {
          ui: {
            featureToggles: {
              mdr_cavc_remand: mdrToggled,
              reversal_cavc_remand: reversalToggled,
              dismissal_cavc_remand: dismissalToggled
            }
          }
        }
      });
  };

  it('renders correctly', () => {
    const { asFragment } = setup({ appealId });

    expect(asFragment()).toMatchSnapshot();
  });

  describe('Type and subtype inputs', () => {
    it('hides remand subtypes if decision type is not "remand"', async () => {
      const { container }=setup({ appealId, reversalToggled: true });

      expect(container.querySelector('#sub-type-options_jmr_jmpr')).toBeInTheDocument();
      const straightReversal = container.querySelector('#type-options_straight_reversal');

      await waitFor(() => {
        expect(straightReversal).toBeInTheDocument();
        expect(straightReversal).toBeEnabled();
      });

      // Simulate user clicking the straight reversal radio button
      fireEvent.click(straightReversal);
      fireEvent.change(straightReversal, { target: { checked: true } });

      expect(straightReversal.checked).toBe(true);
      expect(container.querySelector('#sub-type-options_jmr_jmpr')).not.toBeInTheDocument();
    });
  });

  it('selects all issues on page load', () => {
    const decisionIssues = amaAppeal.decisionIssues;
    setup({ appealId });

    // Get an array of descriptions from decisionIssues
    const descriptions = decisionIssues.map((issue) => issue.description);

    // Create a map of decision issue descriptions to their corresponding checkbox elements
    const checkboxMap = {};

    descriptions.forEach((description) => {
      const checkbox = screen.getByLabelText(description);
      expect(checkbox).toBeInTheDocument();
      checkboxMap[description] = checkbox;
    });

    descriptions.forEach((description) => {
      const checkboxElement = checkboxMap[description];
      expect(checkboxElement).toBeInTheDocument();
      expect(checkboxElement.checked).toBe(true);
    });
  });

  describe('Are judgement and mandate dates provided?', () => {
    let container;

    beforeEach(() => {
        const setupResult = setup({ appealId, reversalToggled: true, mdrToggled: true, dismissalToggled: true });
        container = setupResult.container;
    });
    it('does not appear for Remand type (default case)', () => {
      expect(container.querySelector('#remand-provided-toggle_true')).not.toBeInTheDocument();
    });

    it('appears for Straight Reversal', () => {
      const straightReversal = screen.getByRole('radio', { name: 'Straight Reversal' });
      fireEvent.click(straightReversal);
      expect(container.querySelector('#remand-provided-toggle_true')).toBeInTheDocument();
    });
    it('appears for Death Dismissal', () => {
      const deathDismissal = screen.getByRole('radio', { name: 'Death Dismissal' });
      fireEvent.click(deathDismissal);
      expect(container.querySelector('#remand-provided-toggle_true')).toBeInTheDocument();
    });
  });

  describe('feature toggles', () => {
    describe('mdr_cavc_remand', () => {
      it('hides mdr when not toggled', () => {
        const { container } = setup({ appealId, mdrToggled: false });
        expect(container.querySelector('#sub-type-options_mdr')).not.toBeInTheDocument();
      });

      it('shows mdr when toggled', () => {
        const { container } = setup({ appealId, mdrToggled: true });
        expect(container.querySelector('#sub-type-options_mdr')).toBeInTheDocument();
      });
    });

    describe('reversal_cavc_remand', () => {
      it('hides reversal when not toggled', () => {
        const {container} = setup({ appealId, reversalToggled: false });
        expect(container.querySelector('#type-options_straight_reversal')).not.toBeInTheDocument();
      });

      it('shows reversal when toggled', () => {
        const { container } = setup({ appealId, reversalToggled: true });
        expect(container.querySelector('#type-options_straight_reversal')).toBeInTheDocument();
      });
    });

    describe('dismissal_cavc_remand', () => {
      it('hides dismissal when not toggled', () => {
        const { container } = setup({ appealId, dismissalToggled: false });
        expect(container.querySelector('#type-options_death_dismissal')).not.toBeInTheDocument();
      });

      it('shows dismissal when toggled', () => {
        const { container } = setup({ appealId, dismissalToggled: true });
        expect(container.querySelector('#type-options_death_dismissal')).toBeInTheDocument();
      });
    });
  });

  describe('form validations', () => {
    const errorClass = '.usa-input-error-message';
    const futureDate = moment(new Date().toISOString()).add(2, 'day').
      format('YYYY-MM-DD');
    const submitButton = (screen) => screen.getByRole('button', { name: 'Submit' });

    describe('docket number validations', () => {
      const error = COPY.CAVC_DOCKET_NUMBER_ERROR;

      it('shows error on blank docket number', () => {
        setup({ appealId });

        submitButton(screen).click();
        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('shows error on incorrectly formatted docket number', () => {
        setup({ appealId });
        const docketNumber = screen.getByRole('textbox', { name: 'What is the court docket number?' });
        fireEvent.change(docketNumber, { target: { value: 'bad docket number' } });

        submitButton(screen).click();

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on correctly formatted docket number with dash', () => {
        setup({ appealId });

        const docketNumber = screen.getByRole('textbox', { name: 'What is the court docket number?' });
        fireEvent.change(docketNumber, { target: { value: '20-39283' } });

        submitButton(screen).click();
        expect(screen.queryByText(error)).toBeNull();
      });

      it('does not show error on correctly formatted docket number with hyphen', () => {
        setup({ appealId });

        const docketNumber = screen.getByRole('textbox', { name: 'What is the court docket number?' });
        fireEvent.change(docketNumber, { target: { value: '20‐39283' } });

        submitButton(screen).click();
        expect(screen.queryByText(error)).toBeNull();
      });
    });

    describe('judge name validations', () => {
      const error = COPY.CAVC_JUDGE_ERROR;

      it('shows error on no selected judge', () => {
        setup({ appealId });

        submitButton(screen).click();
        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on selected judge', () => {
        setup({ appealId });

        const dropdown = screen.getByRole('combobox', { name: "What is the CAVC judge's name?" });
        fireEvent.keyDown(dropdown, { key: 'ArrowDown', keyCode: 40 });
        fireEvent.keyDown(dropdown, { key: 'Enter', keyCode: 13 });

        submitButton(screen).click();
        expect(screen.queryByText(error)).toBeNull();
      });
    });

    describe('decision date validations', () => {
      const error = COPY.CAVC_DECISION_DATE_ERROR;

      it('shows error on no selected date', () => {
        setup({ appealId });

        submitButton(screen).click();
        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('shows error on future date selection', () => {
        const {container} = setup({ appealId });

        const decisionDate = container.querySelector('input#decision-date');
        fireEvent.change(decisionDate, { target: { value: futureDate } });

        submitButton(screen).click();

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on selected date', () => {
        const {container} = setup({ appealId });

        const decisionDate = container.querySelector('input#decision-date');
        fireEvent.change(decisionDate, { target: { value: '2020-11-11' } });

        submitButton(screen).click();

        expect(screen.queryByText(error)).toBeNull();
      });
    });

    describe('judgement date validations', () => {
      const error = COPY.CAVC_JUDGEMENT_DATE_ERROR;

      it('shows error on no selected date', () => {
        setup({ appealId });

        const mandateDatesSameToggle = screen.getByRole('checkbox', { name: 'mandate-dates-same-toggle' });
        fireEvent.click(mandateDatesSameToggle);

        submitButton(screen).click();

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('shows error on future date selection', () => {
        const {container}=setup({ appealId });

        const mandateDatesSameToggle = screen.getByRole('checkbox', { name: 'mandate-dates-same-toggle' });
        fireEvent.click(mandateDatesSameToggle);

        const judgementDate = container.querySelector('input#judgement-date');
        fireEvent.change(judgementDate, { target: { value: futureDate } });

        submitButton(screen).click();

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on selected date', () => {
        const {container}=setup({ appealId });

        const mandateDatesSameToggle = screen.getByRole('checkbox', { name: 'mandate-dates-same-toggle' });
        fireEvent.click(mandateDatesSameToggle);

        const judgementDate = container.querySelector('input#judgement-date');
        fireEvent.change(judgementDate, { target: { value: '2020-11-11' } });

        submitButton(screen).click();

        expect(screen.queryByText(error)).toBeNull();
      });
    });

    describe('mandate date validations', () => {
      const error = COPY.CAVC_MANDATE_DATE_ERROR;

      it('shows error on no selected date', () => {
        setup({ appealId });

        const mandateDatesSameToggle = screen.getByRole('checkbox', { name: 'mandate-dates-same-toggle' });
        fireEvent.click(mandateDatesSameToggle);

        submitButton(screen).click();

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('shows error on future date selection', () => {
        const {container}=setup({ appealId });

        const mandateDatesSameToggle = screen.getByRole('checkbox', { name: 'mandate-dates-same-toggle' });
        fireEvent.click(mandateDatesSameToggle);

        const mandateDate = container.querySelector('input#mandate-date');
        fireEvent.change(mandateDate, { target: { value: futureDate } });

        submitButton(screen).click();
        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on selected date', () => {
        const {container}=setup({ appealId });

        const mandateDatesSameToggle = screen.getByRole('checkbox', { name: 'mandate-dates-same-toggle' });
        fireEvent.click(mandateDatesSameToggle);

        const mandateDate = container.querySelector('input#mandate-date');
        fireEvent.change(mandateDate, { target: { value: '2020-11-11' } });

        submitButton(screen).click();

        expect(screen.queryByText(error)).toBeNull();
      });
    });

    describe('issue selection validations', () => {
      const error = COPY.CAVC_ALL_ISSUES_ERROR;

      it('does not show error when any issue is not selected', () => {
        const {container} = setup({ appealId });

        const input2 = container.querySelector('input[id="2"]');
        fireEvent.click(input2);

        submitButton(screen).click();

        expect(screen.queryByText(error)).toBeNull();
      });
    });

    describe('cavc form instructions validations', () => {
      const error = COPY.CAVC_INSTRUCTIONS_ERROR;

      it('shows error on empty instructions', () => {
        const {container} = setup({ appealId });

        const instructions = container.querySelector('textarea#context-and-instructions-textBox');
        fireEvent.change(instructions, { target: { value: '' } });

        submitButton(screen).click();

        expect(screen.getByText(error)).toBeInTheDocument();
      });

      it('does not show error on instructions', () => {
        const {container} = setup({ appealId });

        const instructions = container.querySelector('textarea#context-and-instructions-textBox');
        fireEvent.change(instructions, { target: { value: '2020-11-11' } });

        submitButton(screen).click();

        expect(screen.queryByText(error)).toBeNull();
      });
    });
  });
});
