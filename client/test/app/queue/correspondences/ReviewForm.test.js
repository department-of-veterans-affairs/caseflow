import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import ReviewForm from '../../../../app/queue/correspondence/review_package/ReviewForm';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';

const store = createStore(rootReducer, applyMiddleware(thunk));

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
     const mockFunction = jest.fn();
    props.setCorrTypeSelected = mockFunction;
    render(
      <Provider store={store}>
        <ReviewForm {...props} />;
      </Provider>
    );

    expect(screen.getByText('General Information')).toBeInTheDocument();
    expect(screen.getByText('Veteran file number')).toBeInTheDocument();
    expect(screen.getByText('Veteran name')).toBeInTheDocument();
    expect(screen.getByText('Correspondence type')).toBeInTheDocument();
    expect(screen.getByText('Notes')).toBeInTheDocument();
  });

  it('check if button is disabled', () => {
    const mockFunction = jest.fn();
    props.setCorrTypeSelected = mockFunction;

    render(
      <Provider store={store}>
        <ReviewForm {...props} />
      </Provider>
    );

    const button = screen.getByText('Save changes');

    expect(button).toBeDisabled();
  });

  it('check if button is enable', () => {
    const mockFunction = jest.fn();
    props.setCorrTypeSelected = mockFunction;
    props.setEditableData = mockFunction;
    props.setIsReturnToQueue = mockFunction;

    render(
      <Provider store={store}>
        <ReviewForm {...props} />
      </Provider>
    );

    const inputNode = screen.getByRole('textbox', { name: 'veteran-file-number-input' });

    fireEvent.change(inputNode, { target: { value: '12345678' } });
    expect(mockFunction).toHaveBeenCalledTimes(6);
  });

});
