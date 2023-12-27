import React from 'react';
import { render } from '@testing-library/react';
import { createStore } from '@reduxjs/toolkit';
import LeverButtonsWrapper from './LeverButtonsWrapper';
import leversReducer from '../reducers/Levers/leversReducer';
import { ACTIONS } from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import * as leverData from 'test/data/adminCaseDistributionLevers';

describe('LeverButtonsWrapper', () => {
  let leverStore;
  let buttonsDiv;

  beforeEach(() => {
    const preloadedState = {
      levers: JSON.parse(JSON.stringify(leverData.levers.slice(0, 5))),
      initial_levers: JSON.parse(JSON.stringify(leverData.levers.slice(0, 5)))
    };

    leverStore = createStore(leversReducer, preloadedState);
    buttonsDiv = render(<LeverButtonsWrapper leverStore={leverStore} />);
  });

  describe('Cancel Button', () => {
    it('renders the cancel button correctly', () => {
      const cancelButton = buttonsDiv.container.querySelector('#CancelLeversButton');

      expect(cancelButton).toBeInTheDocument();
    });

    it('sets the levers back to thier initial state when clicked', () => {
      const cancelButton = buttonsDiv.container.querySelector('#CancelLeversButton');

      leverStore.dispatch({
        type: ACTIONS.UPDATE_LEVER_VALUE,
        updated_lever: leverData.lever1_update
      });
      leverStore.dispatch({
        type: ACTIONS.UPDATE_LEVER_VALUE,
        updated_lever: leverData.lever5_update
      });

      expect(leverStore.getState().levers).toEqual(leverData.updated_levers);

      cancelButton.click();

      expect(leverStore.getState().levers).not.toEqual(leverData.updated_levers);
      expect(leverStore.getState().levers).toEqual(leverData.levers.slice(0, 5));
    });
  });

  describe('Save Button', () => {
    it('renders the save button correctly', () => {
      const saveButton = buttonsDiv.container.querySelector('#SaveLeversButton');

      expect(saveButton).toBeInTheDocument();
    });

    it('saves the levers in thier current state when clicked', () => {
      const saveButton = buttonsDiv.container.querySelector('#SaveLeversButton');

      leverStore.dispatch({
        type: ACTIONS.UPDATE_LEVER_VALUE,
        updated_lever: leverData.lever1_update
      });
      leverStore.dispatch({
        type: ACTIONS.UPDATE_LEVER_VALUE,
        updated_lever: leverData.lever5_update
      });

      expect(leverStore.getState().levers).toEqual(leverData.updated_levers);

      saveButton.click();

      expect(leverStore.getState().levers).not.toEqual(leverData.levers.slice(0, 5));
      expect(leverStore.getState().levers).toEqual(leverData.updated_levers);
    });
  });

});
