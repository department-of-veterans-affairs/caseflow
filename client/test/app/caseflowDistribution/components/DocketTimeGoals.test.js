import React from 'react';
import { render, fireEvent } from '@testing-library/react';
import DocketTimeGoals from 'app/caseflowDistribution/components/DocketTimeGoals';
import { levers } from 'test/data/adminCaseDistributionLevers';

jest.mock('app/styles/caseDistribution/InteractableLevers.module.scss', () => '');
describe('DocketTimeGoals Component', () => {
  const mockLeverList = ['lever_10', 'lever_11', 'lever_12'];
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
    component = render(<DocketTimeGoals {...props} />);
  });

  it('renders without crashing', () => {
    expect(component).toBeTruthy();
  });

  it('renders correct number of levers', () => {
    const lev = component.container.querySelectorAll('button');

    expect(lev.length).toBe(props.leverList.length);
  });

  it('renders DocketTimeGoals component correctly', () => {
    expect(component.getByText('AMA Non-priority Distribution Goals by Docket')).toBeInTheDocument();
    expect(component.getByText('Lever 11')).toBeInTheDocument();
  });

  it('updates lever value on input change', () => {
    const leverInput = component.container.querySelector('#toggle-lever_10');

    fireEvent.change(leverInput, { target: { value: '65' } });
    expect(leverInput.value).toBe('65');
    const lever = mockLeverStore.getState().levers.find((lev) => lev.item === 'lever_10');

    expect(lever.value).toBe(65);
  });

  it('toggles lever on switch click', () => {
    const lever = mockLeverStore.getState().levers.find((lev) => lev.item === 'lever_11');

    expect(lever.is_active).toBe(false);
    const leverToggle = component.container.querySelector('#toggle-switch-lever_11');

    fireEvent.click(leverToggle);
    expect(mockLeverStore.getState().levers.find((lev) => lev.item === 'lever_11').is_active).toBe(true);
  });
});
