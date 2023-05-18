import React from 'react';
import { useSelector } from 'react-redux';
import { render, fireEvent } from '@testing-library/react';
import CavcDecisionReasons from '../../../../app/queue/cavcDashboard/CavcDecisionReasons';

jest.mock('react-redux', () => ({
  ...jest.requireActual('react-redux'),
  useSelector: jest.fn(),
  useDispatch: () => jest.fn().mockImplementation(() => Promise.resolve(true))
}));

const checkboxes = [
  {
    id: 1,
    basis_for_selection_category: null,
    decision_reason: 'Duty to notify',
    order: 1,
    parent_decision_reason_id: null
  },
  {
    id: 2,
    basis_for_selection_category: 'null',
    decision_reason: 'Duty to assist',
    order: 2,
    parent_decision_reason_id: null
  },
  {
    id: 3,
    basis_for_selection_category: 'other_due_process_protection',
    decision_reason: 'Other due process protection',
    order: 3,
    parent_decision_reason_id: null
  },
  {
    id: 4,
    basis_for_selection_category: null,
    decision_reason: 'Treatment records',
    order: 1,
    parent_decision_reason_id: 2
  }
];

describe('CavcDecisionReasons', () => {
  it('renders parent checkboxes correctly', () => {
    useSelector.mockReturnValue(checkboxes);
    const { getByLabelText, getByText } = render(<CavcDecisionReasons uniqueId="1234" userCanEdit="true" />);
    const accordion = getByText('Decision Reasons');

    fireEvent.click(accordion);

    expect(getByLabelText('Duty to notify')).toBeInTheDocument();
    expect(getByLabelText('Duty to assist')).toBeInTheDocument();
    expect(getByLabelText('Other due process protection')).toBeInTheDocument();
  });

  it('renders child checkboxes when parent is clicked', () => {
    useSelector.mockReturnValue(checkboxes);
    const { getByLabelText, getByText } = render(<CavcDecisionReasons uniqueId="1234" userCanEdit="true" />);
    const accordion = getByText('Decision Reasons');

    fireEvent.click(accordion);
    const parentCheckbox = getByLabelText('Duty to assist');

    fireEvent.click(parentCheckbox);
    expect(getByLabelText('Treatment records')).toBeInTheDocument();
  });

  it('renders dropdown component when checkbox is checked and selection basis exists', () => {
    useSelector.mockReturnValue(checkboxes);
    const { getByLabelText, getByText } = render(<CavcDecisionReasons uniqueId="1234" userCanEdit="true" />);
    const accordion = getByText('Decision Reasons');

    fireEvent.click(accordion);
    fireEvent.click(getByLabelText('Other due process protection'));

    expect(document.querySelector('input', { name: 'decision-reason-basis-3' })).toBeInTheDocument();
  });
});
