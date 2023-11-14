import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import ReviewForm from '../../../../app/queue/correspondences/reviewPackage/components/ReviewForm';
describe('ReviewForm', () => {
  let props;

  beforeEach(() => {
    props = {
      editableData: {
        veteran_file_number: '500000004',
        notes: 'This is a note from CMP.',
      },
      reviewDetails: {
        veteran_name: 'Bob  Smithbaumbach',
        dropdown_values: ['Option 1', 'Option 2'],
      },
      disableButton: false,
    };
  });

  it('renders the component', () => {
    render(<ReviewForm {...props} />);

    expect(screen.getByText('General Information')).toBeInTheDocument();
    expect(screen.getByText('Veteran file number')).toBeInTheDocument();
    expect(screen.getByText('Veteran name')).toBeInTheDocument();
    expect(screen.getByText('Correspondence Type')).toBeInTheDocument();
    expect(screen.getByText('Notes')).toBeInTheDocument();
  });

  it('check if button is disabled', () => {
    render(<ReviewForm {...props} />);
    const button = screen.getByText('Save Changes');

    expect(button).toBeDisabled();
  });

  it('check if button is enable', () => {
    const mockFunction = jest.fn();

    props.setEditableData = mockFunction;
    render(<ReviewForm {...props} />);
    const inputNode = screen.getByRole('textbox', { name: 'Veteran file number' });

    fireEvent.change(inputNode, { target: { value: 'new value' } });
    expect(mockFunction).toHaveBeenCalledTimes(1);
  });

});
