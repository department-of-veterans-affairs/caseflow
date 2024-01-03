import React from 'react';
import { render, fireEvent } from '@testing-library/react';
import AffinityDays from 'app/caseflowDistribution/components/AffinityDays';
import { levers } from 'test/data/adminCaseDistributionLevers';

jest.mock('app/styles/caseDistribution/InteractableLevers.module.scss', () => '');
describe('AffinityDays Component', () => {
  const mockLeverList = ['lever_9', 'lever_13'];
  const mockLeverStore = {
    getState: jest.fn(() => ({
      levers
    }))
  };
  let props;
  let component;

  beforeEach(() => {
    props = {
      leverList: mockLeverList,
      leverStore: mockLeverStore
    };
    component = render(<AffinityDays {...props} />);
  });

  it('renders without crashing', () => {
    expect(component).toBeTruthy();
  });

  it('renders AffinityDays component correctly', () => {
    expect(component.getByText('Affinity Days')).toBeInTheDocument();
  });

  it('updates lever value on input change', () => {
    const leverInput = component.container.querySelector('#option_2');

    fireEvent.change(leverInput, { target: { value: '65' } });
    expect(leverInput.value).toBe('65');
    const lever = mockLeverStore.getState().levers.find((le) => le.item === 'lever_9');

    expect(lever.options.find((opt) => opt.item === 'option_2').value).toBe(65);
  });

  it('switch radio input change', () => {
    const readioInput1 = component.container.querySelector('#lever_9-option_1');
    const readioInput2 = component.container.querySelector('#lever_9-option_2');

    expect(readioInput1.checked).toEqual(true);
    expect(readioInput2.checked).toEqual(false);
    fireEvent.click(readioInput2);
    expect(readioInput2.checked).toEqual(true);
    expect(readioInput1.checked).toEqual(false);
  });
});
