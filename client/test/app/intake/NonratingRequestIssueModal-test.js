import React from 'react';
import { mount } from 'enzyme';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';

import { VHA_ADMIN_DECISION_DATE_REQUIRED_BANNER } from 'app/../COPY';
import NonratingRequestIssueModal from '../../../app/intake/components/NonratingRequestIssueModal';
import { sample1 } from './testData';
import exp from 'constants';

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
  //     formType={formType}
  //     intakeData={intakeData}
  //     featureToggles={{}}
  //   />
  // );

  // const wrapperEMOPreDocket = render(
  //   <NonratingRequestIssueModal
  //     formType="appeal"
  //     intakeData={intakeData}
  //     featureToggles={featureTogglesEMOPreDocket}
  //   />
  // );

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

    // const cancelBtn = screen.getByRole('button', { name: 'Cancel adding this issue' });


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

      const cancelBtn = await screen.findByRole('button', { name: 'cancel' });
      const skipBtn = await screen.findByRole('button', { name: 'skip' });
      const submitBtn = await screen.findByRole('button', { name: 'submit' });

      expect(cancelBtn.textContent).toBe('cancel');
      expect(skipBtn.textContent).toBe('skip');
      expect(submitBtn.textContent).toBe('submit');
    });

    it.only('skip button only with onSkip prop', async () => {
      // setup();

      // const { container } = setup();
      // const element = container.querySelector('.cf-modal-controls .no-matching-issues');
      // console.log('HELLLLLO????', element);


      // console.log('HELLLLLO????',screen.queryByText('.cf-modal-controls .no-matching-issues'))
      // expect(screen.queryByText('.cf-modal-controls .no-matching-issues')).not.toBeInTheDocument();

      // const newProps = {
      //   onSkip: () => null
      // }

      // const { container } = setup(newProps);
      // const wrapperNoSkip = container.querySelector('.cf-modal-controls .no-matching-issues');

      // console.log("WRAPPERNOSKIP!!",wrapperNoSkip);
      // expect(wrapperNoSkip).toBeInTheDocument();

      const { container } = setup();

      let element;
      await waitFor(() => {
        element = container.querySelector('.cf-modal-controls .no-matching-issues');
        if (!element) {
          throw new Error('Element not yet available');
        }
      });

      console.log('HELLLLLO????', element);
    });

    it('disables button when nothing selected', () => {
      expect(submitBtn.prop('disabled')).toBe(true);

      //   Lots of things required for button to be enabled...
      wrapper.setState({
        benefitType: 'compensation',
        category: {
          label: 'Apportionment',
          value: 'Apportionment'
        },
        decisionDate: '06/01/2019',
        dateError: false,
        description: 'thing'
      });

      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(false);
    });

    it('does not disable button when valid description entered', () => {
      expect(submitBtn.prop('disabled')).toBe(true);

      wrapper.setState({
        benefitType: 'compensation',
        category: {
          label: 'Apportionment',
          value: 'Apportionment'
        },
        decisionDate: '06/01/2019',
        dateError: false,
        description: ''
      });

      // Simulate user input of valid characters
      const descInput = wrapper.find("input[id='Issue description']");

      descInput.simulate('change', { target: { value: '1234567890-=`~!@#$%^&*()_+[]{}\\|;:' } });

      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(false);
    });

    it('disables button when invalid description entered', () => {
      expect(submitBtn.prop('disabled')).toBe(true);

      wrapper.setState({
        benefitType: 'compensation',
        category: {
          label: 'Apportionment',
          value: 'Apportionment'
        },
        decisionDate: '06/01/2019',
        dateError: false,
        description: ''
      });

      // Simulate user input of invalid characters
      const descInput = wrapper.find("input[id='Issue description']");

      descInput.simulate('change', { target: { value: 'Not safe: \u{00A7} \u{2600} \u{2603} \u{260E} \u{2615}' } });

      expect(wrapper.find('.cf-modal-controls .add-issue').prop('disabled')).toBe(true);
      expect(wrapper.find('.usa-input-error-message').text()).toBe('Invalid character');
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
