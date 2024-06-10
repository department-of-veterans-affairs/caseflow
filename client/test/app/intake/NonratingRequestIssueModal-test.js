import React from 'react';
import { mount } from 'enzyme';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { VHA_ADMIN_DECISION_DATE_REQUIRED_BANNER } from 'app/../COPY';
import NonratingRequestIssueModal from '../../../app/intake/components/NonratingRequestIssueModal';
import { sample1 } from './testData';
import exp from 'constants';
import { on } from 'events';
import { ge } from 'faker/lib/locales';
import { get } from 'lodash';

import { act } from 'react-dom/test-utils';

describe('NonratingRequestIssueModal', () => {
  const formType = 'higher_level_review';
  const intakeData = sample1.intakeData;
  const featureTogglesEMOPreDocket = { eduPreDocketAppeals: true };

  // const wrapper = render(
  //   <NonratingRequestIssueModal
  //     formType={formType}
  //     intakeData={intakeData}
  //     onSkip={() => null}
  //     featureToggles={{}}
  //   />
  // );

  // const wrapperNoSkip = render(
  //   <NonratingRequestIssueModal
      // formType={formType}
      // intakeData={intakeData}
      // featureToggles={{}}
  //   />
  // );

  // const wrapperEMOPreDocket = render(
  //   <NonratingRequestIssueModal
      // formType="appeal"
      // intakeData={intakeData}
      // featureToggles={featureTogglesEMOPreDocket}
  //   />
  // );

  describe('renders', () => {


    const defaultProps = {
      benefitType: 'compensation',
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
    // const cancelBtn = screen.getByRole('button', { name: 'Cancel adding this issue' });

    // const {container} = setup();
    // const cancelBtn = container.querySelector('.cf-modal-controls .close-modal');
    // const skipBtn = container.querySelector('.cf-modal-controls .no-matching-issues');
    // const submitBtn = container.querySelector('.cf-modal-controls .add-issue');


    it('renders button text', () => {
      setup();
      expect(screen.getByText('Cancel adding this issue')).toBeInTheDocument();
      expect(screen.getByText('None of these match, see more options')).toBeInTheDocument();
      expect(screen.getByText('Add this issue')).toBeInTheDocument();
    });

    it('renders with new props', async () => {
      const newProps = {
        cancelText: 'cancel',
        skipText: 'skip',
        submitText: 'submit'
      };

      setup(newProps);

      const cancelBtn = await screen.findByText('cancel');
      const skipBtn = await screen.findByText('skip');
      const submitBtn = await screen.findByText('submit');

      expect(cancelBtn.textContent).toBe('cancel');
      expect(skipBtn.textContent).toBe('skip');
      expect(submitBtn.textContent).toBe('submit');
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
      const submitBtn = container.querySelector('.cf-modal-controls .add-issue');
      // console.log("SUBMIT BUTTON!!",submitBtn);
      // expect(submitBtn.prop('disabled')).toBe(true);
      expect(submitBtn).toBeDisabled();

      //   Lots of things required for button to be enabled...
      // wrapper.setState({
      //   benefitType: 'compensation',
      //   category: {
      //     label: 'Apportionment',
      //     value: 'Apportionment'
      //   },
      //   decisionDate: '06/01/2019',
      //   dateError: false,
      //   description: 'thing'
      // });

      // expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(false);
    });

    it.only('enables the button when all required fields are filled in', async () => {
      // Define new props
      const newProps = {
        benefitType: 'compensation',
        category: {
          label: 'Apportionment',
          value: 'Apportionment'
        },
        decisionDate: '06/01/2019',
        dateError: false,
        description: 'thing',
        formType: 'someFormType', // Ensure this matches the expected form type
        intakeData: {
          benefitType: 'compensation',
          activeNonratingRequestIssues: [
            {
              category: 'Apportionment',
              // other properties if needed
            }
          ]
        },
        onSkip: () => null,
        featureToggles: {
          featureTogglesEMOPreDocket: false, // Set any other required feature toggles here
          eduPreDocketAppeals: false,
          mstIdentification: false,
          pactIdentification: false,
        }
      };


      // Pass the initial state as props when you render the component
      render(<NonratingRequestIssueModal {...newProps} />);

      const categoryInput = screen.getByLabelText('Issue category');
      userEvent.type(categoryInput, 'Apportionment');

      const decisionDateInput = screen.getByLabelText('Decision date');
      userEvent.type(decisionDateInput, '2019-06-01');

      const descriptionInput = screen.getByLabelText('Issue description');
      userEvent.type(descriptionInput, 'thing');
      // fireEvent.change(descriptionInput, { target: { value: 'thing' } });

      const addIssueButton = await waitFor(() => screen.getByRole('button', { name: 'Add this issue', disabled: false }));

      // Log the button and its parent elements to understand their state

      // console.log(screen.getByRole('button', {name: 'Add this issue'}));
      // Wait for the 'add-issue' button to be enabled
      // let addIssueButton;
      await waitFor(() => {
        console.log('Button Enabled:', addIssueButton);
        // addIssueButton = container.querySelector('.cf-modal-controls .add-issue');
        // console.log('Button Disabled:', addIssueButton);
        // expect(addIssueButton).not.toBeNull();
        // expect(addIssueButton.disabled).toBe(false);
      });
    });

  });

  describe('on appeal, with EMO Pre-Docket', () => {
    const preDocketRadioField = wrapperEMOPreDocket.find('.cf-is-predocket-needed');

    wrapperEMOPreDocket.setState({
      benefitType: 'education',
      category: {
        label: 'accrued',
        value: 'accrued'
      },
      decisionDate: '03/30/2022',
      dateError: false,
      description: 'thing',
      isPreDocketNeeded: null
    });

    it(' enabled selecting benefit type of "education" renders PreDocketRadioField', () => {
      // Benefit type isn't education, so it should not be rendered
      expect(preDocketRadioField).toHaveLength(0);

      wrapperEMOPreDocket.setState({
        benefitType: 'education'
      });

      // Benefit type is now education, so it should be rendered
      expect(wrapperEMOPreDocket.find('.cf-is-predocket-needed')).toHaveLength(1);
    });

    it('Decision date does not have an optional label ', () => {
      // Since this is a non vha benifit type the decision date is required, so the optional label should not be visible
      const optionalLabel = wrapperEMOPreDocket.find('.decision-date .cf-optional');
      const submitButton = wrapperEMOPreDocket.find('.cf-modal-controls .add-issue');

      expect(optionalLabel).not.toBe();
      expect(submitButton.prop('disabled')).toBe(true);
    });

    it('submit button is disabled with Education benefit_type if pre-docket selection is empty', () => {
      // Switch to an Education issue, but don't fill in pre-docket field
      const submitBtn = wrapperEMOPreDocket.find('.cf-modal-controls .add-issue');

      expect(submitBtn.prop('disabled')).toBe(true);

      // Fill in pre-docket field to make sure the submit button gets enabled
      // Note that the radio field values are strings.
      wrapperEMOPreDocket.setState({
        isPreDocketNeeded: 'false'
      });

      expect(wrapperEMOPreDocket.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(false);
    });
  });

  describe('on higher level review, with VHA benefit type', () => {
    wrapperNoSkip.setState({
      benefitType: 'vha',
      category: {
        label: 'Beneficiary Travel',
        value: 'Beneficiary Travel'
      },
      description: 'test'
    });

    console.log("WRAPPERSKIP!!",wrapperNoSkip.benefitType);

    // let benefitTypeInput = wrapperNoSkip.getByLabelText('Benefit Type');
    // let categoryInput = wrapperNoSkip.getByLabelText('Category');
    // let descriptionInput = wrapperNoSkip.getByLabelText('Description');

    // fireEvent.change(benefitTypeInput, { target: { value: 'vha' } });
    // fireEvent.change(categoryInput, { target: { value: 'Beneficiary Travel' } });
    // fireEvent.change(descriptionInput, { target: { value: 'test' } });

    const optionalLabel = wrapperNoSkip.getByLabelText('.decision-date .cf-optional');
    console.log("OPTIONAL LABEL!!",optionalLabel);
    const submitButton = wrapperNoSkip.find('.cf-modal-controls .add-issue');

    it('renders modal with decision date field being optional', () => {
      expect(optionalLabel.text()).toBe('Optional');
    });

    it('submit button is enabled without a decision date entered', () => {
      expect(submitButton.prop('disabled')).toBe(false);
    });
  });

  describe('on higher level review, with VHA Admin and Task on Progress', () => {
    wrapperNoSkip.setState({
      benefitType: 'vha',
      isTaskInProgress: true,
      userIsVhaAdmin: true,
      category: {
        label: 'Beneficiary Travel',
        value: 'Beneficiary Travel'
      },
      description: 'VHA data test'
    });

    const optionalLabel = wrapperNoSkip.find('.decision-date .cf-optional');
    const submitButton = wrapperNoSkip.find('.cf-modal-controls .add-issue');
    const alertText = wrapperNoSkip.find('.usa-alert-text');

    it('renders modal with Decision date required alert banner', () => {
      expect(alertText.text()).toContain(VHA_ADMIN_DECISION_DATE_REQUIRED_BANNER);
    });

    it('renders modal without Decision date optional text', () => {
      expect(optionalLabel).not.toBe();
      expect(submitButton.prop('disabled')).toBe(true);
    });
  });

  describe('on higher level review, with VHA Admin User and Task not in Progress', () => {
    wrapperNoSkip.setState({
      benefitType: 'vha',
      isTaskInProgress: false,
      userIsVhaAdmin: true,
      category: {
        label: 'Beneficiary Travel',
        value: 'Beneficiary Travel'
      },
      description: 'VHA data test'
    });

    const optionalLabel = wrapperNoSkip.find('.decision-date .cf-optional');
    const submitButton = wrapperNoSkip.find('.cf-modal-controls .add-issue');
    const alertBody = wrapperNoSkip.find('.usa-alert-body');

    it('renders modal without Decision date required alert banner', () => {
      expect(alertBody.exists()).toBe(false);
    });

    it('renders modal without Decision date optional text', () => {
      expect(optionalLabel.text()).toBe('Optional');
      expect(submitButton.prop('disabled')).toBe(false);
    });
  });
});
