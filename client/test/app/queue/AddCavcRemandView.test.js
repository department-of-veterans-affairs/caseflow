import React from 'react';
import { mount } from 'enzyme';

import { queueWrapper } from 'test/data/stores/queueStore';
import { amaAppeal } from 'test/data/appeals';

import AddCavcRemandView from 'app/queue/AddCavcRemandView';
import { SearchableDropdown } from 'app/components/SearchableDropdown';
import CheckboxGroup from 'app/components/CheckboxGroup';

import COPY from 'COPY';

describe('AddCavcRemandView', () => {
  beforeEach(() => jest.clearAllMocks());

  const appealId = amaAppeal.externalId;

  const setup = ({ appealId: id, mdrToggled, reversalToggled, dismissalToggled }) => {
    return mount(
      <AddCavcRemandView appealId={id} />,
      {
        wrappingComponent: queueWrapper,
        wrappingComponentProps: {
          ui: {
            featureToggles: {
              cavc_remand: true,
              mdr_cavc_remand: mdrToggled,
              reversal_cavc_remand: reversalToggled,
              dismissal_cavc_remand: dismissalToggled
            }
          }
        }
      });
  };

  it('renders correctly', async () => {
    const cavcForm = setup({ appealId });

    expect(cavcForm).toMatchSnapshot();
  });

  it('hides remand subtypes if decision type is not "remand"', () => {
    const cavcForm = setup({ appealId, reversalToggled: true });

    expect(cavcForm.find('#sub-type-options_jmr').length).toBe(1);
    cavcForm.find('#type-options_straight_reversal').simulate('change', { target: { checked: true } });
    expect(cavcForm.find('#sub-type-options_jmr').length).toBe(0);
  });

  it('selects all issues on page load', () => {
    const descisionIssues = amaAppeal.decisionIssues;
    const cavcForm = setup({ appealId });
    const decisionIssueChecks = cavcForm.find(CheckboxGroup).props().values;

    expect(descisionIssues.map((issue) => issue.id).every((id) => decisionIssueChecks[id])).toBeTruthy();
  });

  describe('feature toggles', () => {
    describe('mdr_cavc_remand', () => {
      it('hides mdr when not toggled', () => {
        const cavcForm = setup({ appealId, mdrToggled: false });

        expect(cavcForm.find('#sub-type-options_mdr').length).toBe(0);
      });

      it('shows mdr when toggled', () => {
        const cavcForm = setup({ appealId, mdrToggled: true });

        expect(cavcForm.find('#sub-type-options_mdr').length).toBe(1);
      });
    });

    describe('reversal_cavc_remand', () => {
      it('hides reversal when not toggled', () => {
        const cavcForm = setup({ appealId, reversalToggled: false });

        expect(cavcForm.find('#type-options_straight_reversal').length).toBe(0);
      });

      it('shows reversal when toggled', () => {
        const cavcForm = setup({ appealId, reversalToggled: true });

        expect(cavcForm.find('#type-options_straight_reversal').length).toBe(1);
      });
    });

    describe('dismisal_cavc_remand', () => {
      it('hides dismissal when not toggled', () => {
        const cavcForm = setup({ appealId, dismissalToggled: false });

        expect(cavcForm.find('#type-options_death_dismissal').length).toBe(0);
      });

      it('shows dismissal when toggled', () => {
        const cavcForm = setup({ appealId, dismissalToggled: true });

        expect(cavcForm.find('#type-options_death_dismissal').length).toBe(1);
      });
    });
  });

  describe('form validations', () => {
    const errorClass = '.usa-input-error-message';

    const validationErrorShows = (component, errorMessage) => {
      component.find('#button-next-button').simulate('click');

      return component.find(errorClass).findWhere((node) => node.props().children === errorMessage).length > 0;
    };

    describe('docket number validations', () => {
      const error = COPY.CAVC_DOCKET_NUMBER_ERROR;

      it('shows error on blank docket number', () => {
        const cavcForm = setup({ appealId });

        expect(validationErrorShows(cavcForm, error)).toBeTruthy();
      });

      it('shows error on incorrectly formatted docket number', () => {
        const cavcForm = setup({ appealId });

        cavcForm.find('#docket-number').simulate('change', { target: { value: 'bad docket number' } });

        expect(validationErrorShows(cavcForm, error)).toBeTruthy();
      });

      it('does not show error on correctly formatted docket number', () => {
        const cavcForm = setup({ appealId });

        cavcForm.find('input#docket-number').simulate('change', { target: { value: '20-39283' } });

        expect(validationErrorShows(cavcForm, error)).toBeFalsy();
      });
    });

    describe('judge name validations', () => {
      const error = COPY.CAVC_JUDGE_ERROR;

      it('shows error on no selected judge', () => {
        const cavcForm = setup({ appealId });

        expect(validationErrorShows(cavcForm, error)).toBeTruthy();
      });

      it('does not show error on selected judge', () => {
        const cavcForm = setup({ appealId });
        const dropdown = cavcForm.find(SearchableDropdown);

        // Select the first judge and press enter!
        dropdown.find('Select').simulate('keyDown', { key: 'ArrowDown', keyCode: 40 });
        dropdown.find('Select').simulate('keyDown', { key: 'Enter', keyCode: 13 });

        expect(validationErrorShows(cavcForm, error)).toBeFalsy();
      });
    });

    describe('decision date validations', () => {
      const error = COPY.CAVC_DECISION_DATE_ERROR;

      it('shows error on no selected date', () => {
        const cavcForm = setup({ appealId });

        expect(validationErrorShows(cavcForm, error)).toBeTruthy();
      });

      it('does not show error on selected date', () => {
        const cavcForm = setup({ appealId });

        cavcForm.find('input#decision-date').simulate('change', { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcForm, error)).toBeFalsy();
      });
    });

    describe('judgement date validations', () => {
      const error = COPY.CAVC_JUDGEMENT_DATE_ERROR;

      it('shows error on no selected date', () => {
        const cavcForm = setup({ appealId });

        expect(validationErrorShows(cavcForm, error)).toBeTruthy();
      });

      it('does not show error on selected date', () => {
        const cavcForm = setup({ appealId });

        cavcForm.find('input#judgement-date').simulate('change', { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcForm, error)).toBeFalsy();
      });
    });

    describe('mandate date validations', () => {
      const error = COPY.CAVC_MANDATE_DATE_ERROR;

      it('shows error on no selected date', () => {
        const cavcForm = setup({ appealId });

        expect(validationErrorShows(cavcForm, error)).toBeTruthy();
      });

      it('does not show error on selected date', () => {
        const cavcForm = setup({ appealId });

        cavcForm.find('input#mandate-date').simulate('change', { target: { value: '2020-11-11' } });

        expect(validationErrorShows(cavcForm, error)).toBeFalsy();
      });
    });
  });
});
