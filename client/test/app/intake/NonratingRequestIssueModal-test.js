import React from 'react';
import { render, fireEvent, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { VHA_ADMIN_DECISION_DATE_REQUIRED_BANNER } from 'app/../COPY';
import NonratingRequestIssueModal from '../../../app/intake/components/NonratingRequestIssueModal';
import { sample1 } from './testData';
import { testRenderingWithNewProps } from '../../helpers/testHelpers';

describe('NonratingRequestIssueModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;
  const featureTogglesEMOPreDocket = { eduPreDocketAppeals: true };

  describe('renders', () => {
    const defaultProps = {
      formType: formType,
      intakeData: intakeData,
      onSkip: () => null,
      featureToggles: {},
    };

    const setup = (props) => {
      return render(
        <NonratingRequestIssueModal
          {...defaultProps} {...props}
        />
      );
    }

    it('renders button text', () => {
      setup();
      expect(screen.getByText('Cancel adding this issue')).toBeInTheDocument();
      expect(screen.getByText('None of these match, see more options')).toBeInTheDocument();
      expect(screen.getByText('Add this issue')).toBeInTheDocument();
    });

    it('renders with new props', async () => {
      testRenderingWithNewProps(setup);
    });

    it('skip button when onSkip prop is not defined', () => {
      const props = {
        formType: formType,
        intakeData: intakeData,
        featureToggles: {},
        onSkip: undefined,
      };

      const { container } = setup(props);
      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).not.toBeInTheDocument();
    });

    it('shows button when onSkip prop is defined', () => {
      const { container } = setup();
      expect(container.querySelector('.cf-modal-controls .no-matching-issues')).toBeInTheDocument();
    });

    it('disables button when nothing selected', () => {
      setup();
      const submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).toBeDisabled();
    });

    it('enables the button when all required fields are filled in', () => {
      const { container, rerender } = setup();

      let submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).toBeDisabled();

      rerender(
        <NonratingRequestIssueModal
          {...defaultProps}
          category={{
            label: 'Apportionment',
            value: 'Apportionment'
          }}
          decisionDate={'2019-06-01'}
          dateError={false}
          description={'thing'}
          benefitType={'compensation'}
          featureToggles={{}}
        />
      );

      // Fill out Issue category
      let issueCategoryInput = screen.getByRole('combobox', { name: /Issue category/i });
      userEvent.click(issueCategoryInput); // open the dropdown menu
      userEvent.type(issueCategoryInput, 'Apportionment{enter}'); // select the option

      // Fill out Decision Date
      let decisionDateInput = container.querySelector('input[id="decision-date"]');
      fireEvent.change(decisionDateInput, { target: { value: '2019-06-01' } });

      // Fill out Issue description
      let inputElement = container.querySelector('input[id="Issue description"]');
      fireEvent.change(inputElement, { target: { value: 'blah blah' } });

      submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).not.toBeDisabled();
    });

    it('does not disable button when valid description entered', () => {
      const { container, rerender } = setup();

      let submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).toBeDisabled();

      rerender(
        <NonratingRequestIssueModal
          {...defaultProps}
          category={{
            label: 'Apportionment',
            value: 'Apportionment'
          }}
          decisionDate={'2019-06-01'}
          dateError={false}
          description={''}
        />
      );

      let issueCategoryInput = screen.getByRole('combobox', { name: /Issue category/i });
      userEvent.click(issueCategoryInput); // open the dropdown menu
      userEvent.type(issueCategoryInput, 'Apportionment{enter}'); // select the option

      // Fill out Decision Date
      let decisionDateInput = container.querySelector('input[id="decision-date"]');
      fireEvent.change(decisionDateInput, { target: { value: '2019-06-01' } });

      // Fill out Issue description
      let inputElement = container.querySelector('input[id="Issue description"]');
      fireEvent.change(inputElement, { target: { value: '1234567890-=`~!@#$%^&*()_+[]{}\\|;:' } });

      submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).not.toBeDisabled();
    });

    it('disables button when invalid description entered', () => {
      const { container, rerender } = setup();

      let submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).toBeDisabled();

      rerender(
        <NonratingRequestIssueModal
          {...defaultProps}
          benefitType= 'compensation'
          category={{
            label: 'Apportionment',
            value: 'Apportionment'
          }}
          decisionDate={'2019-06-01'}
          dateError={false}
          description={''}
        />
      );

      // Simulate user input of invalid characters
      let issueCategoryInput = screen.getByRole('combobox', { name: /Issue category/i });
      userEvent.click(issueCategoryInput); // open the dropdown menu
      userEvent.type(issueCategoryInput, 'Apportionment{enter}'); // select the option

      // Fill out Decision Date
      let decisionDateInput = container.querySelector('input[id="decision-date"]');
      fireEvent.change(decisionDateInput, { target: { value: '2019-06-01' } });

      // Fill out Issue description
      let inputElement = container.querySelector('input[id="Issue description"]');
      fireEvent.change(inputElement, { target: { value: 'Not safe: \u{00A7} \u{2600} \u{2603} \u{260E} \u{2615}' } });

      submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).toBeDisabled();

      expect(screen.getByText('Invalid character')).toBeInTheDocument();
      expect(container.querySelector('.usa-input-error-message')).toBeInTheDocument();
    });
  });

  describe('on appeal, with EMO Pre-Docket', () => {
    const defaultProps = {
      formType: "appeal",
      intakeData: intakeData,
      featureToggles: featureTogglesEMOPreDocket
    }

    const setup = (props) => {
      return render (
        <NonratingRequestIssueModal
          {...defaultProps} {...props}
        />
      );
    }

    it(' enabled selecting benefit type of "education" renders PreDocketRadioField', async () => {
      const props = {
        benefitType: 'education',
        formType: 'appeal',
        intakeData: intakeData,
        featureToggles: featureTogglesEMOPreDocket,
        category: {
          label: 'accrued',
          value: 'accrued'
        },
        decisionDate: '2022-03-30',
        dateError: false,
        description: 'thing',
        isPreDocketNeeded: null
      };

      setup(props);

      // Benefit type isn't education, so it should not be rendered
      let yesRadio = screen.queryByRole('radio', { name: /Yes/i });
      let noRadio = screen.queryByRole('radio', { name: /No/i });

      expect(yesRadio).not.toBeInTheDocument();
      expect(noRadio).not.toBeInTheDocument();


      const benefitTypeCombobox = screen.getByRole('combobox', { name: /Benefit type/i });
      userEvent.click(benefitTypeCombobox); // open the dropdown menu
      userEvent.type(benefitTypeCombobox, 'Education{enter}'); // select the option

      // Benefit type is now education, so it should be rendered
      yesRadio = screen.queryByRole('radio', { name: /Yes/i });
      noRadio = screen.queryByRole('radio', { name: /No/i });

      expect(yesRadio).toBeInTheDocument();
      expect(noRadio).toBeInTheDocument();
    });

    it('Decision date does not have an optional label ', () => {
      const {container} = setup();

      const submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).toBeDisabled();

      // Since this is a non vha benifit type the decision date is required, so the optional label should not be visible
      const optionalLabel = container.querySelector('.decision-date .cf-optional');
      expect(optionalLabel).not.toBeInTheDocument();
    });

    it('submit button is disabled with Education benefit_type if pre-docket selection is empty', () => {
      const {container} = setup();

      // Switch to an Education issue, but don't fill in pre-docket field
      const benefitTypeCombobox = screen.getByRole('combobox', { name: /Benefit type/i });
      userEvent.click(benefitTypeCombobox); // open the dropdown menu
      userEvent.type(benefitTypeCombobox, 'Education{enter}'); // select the option

      let submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).toBeDisabled();

      const noRadio = screen.queryByRole('radio', { name: /No/i });
      userEvent.click(noRadio);

      // Fill out Issue category
      const issueCategoryInput = screen.getByRole('combobox', { name: /Issue category/i });
      userEvent.click(issueCategoryInput); // open the dropdown menu
      userEvent.type(issueCategoryInput, 'Accrued{enter}'); // select the option

      // Fill out Decision Date
      const decisionDateInput = container.querySelector('input[id="decision-date"]');
      fireEvent.change(decisionDateInput, { target: { value: '2019-06-01' } });

      // Fill out Issue description
      const inputElement = container.querySelector('input[id="Issue description"]');
      fireEvent.change(inputElement, { target: { value: 'blah blah' } });

      submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).not.toBeDisabled();
    });
  });

  describe('on higher level review, with VHA benefit type', () => {
    const defaultProps = {
      category: {
        label: 'Beneficiary Travel',
        value: 'Beneficiary Travel'
      },
      description: 'test',
      formType: formType,
      intakeData: {
        ...intakeData,
        benefitType: 'vha'
      },
      featureToggles: featureTogglesEMOPreDocket
    }

    const setup = (props) => {
      return render (
        <NonratingRequestIssueModal
          {...defaultProps} {...props}
        />
      );
    };

    it('renders modal with decision date field being optional', () => {
      setup();

      const optionalLabel = screen.queryByText('Optional');
      expect(optionalLabel).toBeInTheDocument();
    });

    it('submit button is enabled without a decision date entered', () => {
      setup();
      let submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).toBeDisabled();

      // Fill out Issue category
      const issueCategoryInput = screen.getByRole('combobox', { name: /Issue category/i });
      userEvent.click(issueCategoryInput); // open the dropdown menu
      userEvent.type(issueCategoryInput, 'Beneficiary Travel{enter}'); // select the option

      // Fill out Issue description
      const issueDescriptionTextbox = screen.getByRole('textbox', { name: /Issue description/i });
      fireEvent.change(issueDescriptionTextbox, { target: { value: 'blah blah' } });

      submitBtn = screen.getByRole('button', { name: /Add this issue/i });
      expect(submitBtn).not.toBeDisabled();
    });
  });

  describe('on higher level review, with VHA Admin and Task on Progress', () => {
    const props = {
      benefitType: 'vha',
      formType: formType,
      intakeData: {
        ...intakeData,
        benefitType: 'vha',
        taskInProgress: true,
        addedIssues: [],
        activeNonratingRequestIssues: []

      },
      userIsVhaAdmin: true,
      userCanEditIntakeIssues: true,
      featureToggles: {},
    };

    beforeEach(() => {
      const {container} = render(<NonratingRequestIssueModal {...props} />);
    });

    it('renders modal with Decision date required alert banner', () => {
      expect(screen.getByText(VHA_ADMIN_DECISION_DATE_REQUIRED_BANNER)).toBeInTheDocument();
    });

    it('renders modal without Decision date optional text', () => {
      const optionalLabel = screen.queryByText(/optional/i);
      const submitButton = screen.getByRole('button', { name: /Add this issue/i });

      expect(optionalLabel).not.toBeInTheDocument();
      expect(submitButton).toBeDisabled();
    });
  });

  describe('on higher level review, with VHA Admin User and Task not in Progress', () => {
    const props = {
      benefitType: 'vha',
      formType: formType,
      intakeData: {
        ...intakeData,
        benefitType: 'vha',
        taskInProgress: false,
        addedIssues: [],
        activeNonratingRequestIssues: []

      },
      userIsVhaAdmin: true,
      userCanEditIntakeIssues: true,
      featureToggles: {},
    };

    beforeEach(() => {
      render(<NonratingRequestIssueModal {...props} />);
    });

    it('renders modal without Decision date required alert banner', () => {
      expect(screen.queryByText(VHA_ADMIN_DECISION_DATE_REQUIRED_BANNER)).not.toBeInTheDocument();
    });

    it('renders modal without Decision date optional text', () => {
      const optionalLabel = screen.getByText(/Optional/i);
      const submitButton = screen.getByRole('button', { name: /Add this issue/i });

      const issueCategoryInput = screen.getByRole('combobox', { name: /Issue category/i });
      userEvent.click(issueCategoryInput); // open the dropdown menu
      userEvent.type(issueCategoryInput, 'Beneficiary Travel{enter}'); // select the option

      const issueDescriptionTextbox = screen.getByRole('textbox', { name: /Issue description/i });
      fireEvent.change(issueDescriptionTextbox, { target: { value: 'blah blah' } });

      expect(optionalLabel).toBeInTheDocument();
      expect(submitButton).not.toBeDisabled();
    });
  });
});
