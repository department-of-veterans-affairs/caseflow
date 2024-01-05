import React from 'react';
import { render, fireEvent } from '@testing-library/react';
import BatchSize from 'app/caseDistribution/components/BatchSize';
import { levers } from 'test/data/adminCaseDistributionLevers';

jest.mock('app/styles/caseDistribution/InteractableLevers.module.scss', () => '');
describe('BatchSize', () => {
  let props;
  let component;

  beforeEach(() => {
    props = {
      leverList: ['lever_5', 'lever_6', 'lever_7', 'lever_8'],
      leverStore: {
        getState: jest.fn().mockReturnValue({
          levers
        })
      }
    };
    component = render(<BatchSize {...props} />);
  });

  it('renders without crashing', () => {
    expect(component).toBeTruthy();
  });

  it('renders correct number of levers', () => {
    const lev = component.container.querySelectorAll('input');

    expect(lev.length).toBe(props.leverList.length);
  });

  it('updates lever value and error message on input change', () => {
    const leverInput = component.container.querySelector('#lever_5');

    fireEvent.change(leverInput, { target: { value: '100089' } });
    expect(leverInput.value).toBe('100089');
    expect(component.getByText('Please enter a value less than or equal to 999')).toBeInTheDocument();

  });
});
