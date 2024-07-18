import React, { useState } from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import ReviewForm from '../../../../app/queue/correspondence/ReviewPackage/ReviewForm';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';
import { correspondenceData, packageDocumentTypeData, correspondenceTypes } from 'test/data/correspondence';
let initialState = {
  reviewPackage: {
    correspondence: correspondenceData,
    packageDocumentType: packageDocumentTypeData,
    correspondenceTypes,
    correspondenceTypeId: 1
  }
};


const store = createStore(rootReducer, initialState, applyMiddleware(thunk));

describe('ReviewForm', () => {
  let props;

  beforeEach(() => {
    props = {
      veteranFileNumber: '500000004',
      notes: 'This is a note from CMP',
      blockingTaskId: 12,
      disableButton: false,
      correspondenceData,
      correspondenceTypes,
      correspondenceTypeId: 1,
      setVeteranFileNumber: () => {},
      setDisableSaveButton: () => {}

    };
  });



  it('renders the component', () => {
    props.setCorrTypeSelected = jest.fn();
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
});
