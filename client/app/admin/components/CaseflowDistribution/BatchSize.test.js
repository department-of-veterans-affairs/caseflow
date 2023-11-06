import React from 'react';
import { render, fireEvent } from '@testing-library/react';
import BatchSize from './BatchSize';
import { levers } from 'test/data/adminCaseDistributionLevers';

describe('BatchSize', () => {
  let props;
  let component;

  beforeEach(() => {
    props = {
      leverList: ['lever_5', 'lever_6', 'lever_7', 'lever_8'],
      leverStore: {
        getState: jest.fn().mockReturnValue({
          levers: levers
        })
      }
    };
    component = render(<BatchSize {...props} />);
  });

  it('renders without crashing', () => {
    expect(component).toBeTruthy();
  });

  it('renders correct number of levers', () => {
    const levers = component.container.querySelectorAll('input');
    expect(levers.length).toBe(props.leverList.length);
  });

  it('updates lever value and error message on input change', () => {
    const leverInput = component.container.querySelector('#lever_5');
    fireEvent.change(leverInput, { target: { value: '100089' } });
    expect(leverInput.value).toBe('100089');
    expect(component.getByText('Please enter a value less than or equal to 999')).toBeInTheDocument();

  });
});
