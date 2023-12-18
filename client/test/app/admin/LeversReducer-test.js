import leversReducer from '../../../app/caseflowDistribution/reducers/Levers/leversReducer';
import * as Constants from '../../../app/caseflowDistribution/reducers/Levers/leversActionTypes';
import * as leverData from '../../data/adminCaseDistributionLevers';
import { createStore } from "@reduxjs/toolkit";

/* eslint-disable no-undefined */

describe('Lever reducer', () => {

  let leverStore;

  beforeEach(() => {
    const preloadedState = {
      levers: JSON.parse(JSON.stringify(leverData.levers.slice(0,5))), //allows original leverData object to remain unchanged
      initial_levers: JSON.parse(JSON.stringify(leverData.levers.slice(0,5)))
    }
    leverStore = createStore(leversReducer, preloadedState);
  })

  describe('Initialize reducer', () => {
    it('creates a reducer with the initial state based on the levers passed in', () => {
      expect(leverStore.getState().levers).toEqual(leverData.levers.slice(0,5))
    });
  });

  describe(Constants.FORMAT_LEVER_HISTORY, () => {
    it('returns a formatted lever history array', () => {
      leverStore.dispatch({
        type: Constants.FORMAT_LEVER_HISTORY,
        history: leverData.history
      })

      expect(leverStore.getState().formatted_history).toEqual(leverData.formatted_history)
    });

    // it('returns error message when input is not in correct format', () => {});
  });

  describe(Constants.UPDATE_LEVER_VALUE, () => {
    const levers = leverData.levers.slice(0,5)

    it('updates the current levers with the new value', () => {
      const lever_update = {
        "item": "lever_1",
        "title": "Lever 1",
        "description": "This is the first lever. It is a boolean with the default value of true. Therefore there should be a two radio buttons that display true and false as the example with true being the default option chosen. This lever is active so it should be in the active lever section",
        "data_type": "boolean",
        "value": false,
        "unit": "",
        "is_active": true
      }

      leverStore.dispatch({
        type: Constants.UPDATE_LEVER_VALUE,
        updated_lever: lever_update
      })

      let target_store_lever = leverStore.getState().levers.find(lever => lever.item === "lever_1");
      let target_store_inital_lever = leverStore.getState().initial_levers.find(lever => lever.item === "lever_1");
      let changesOccurred = leverStore.getState().changesOccurred
      let saveChangesActivated = leverStore.getState().saveChangesActivated

      expect(target_store_lever).toEqual(lever_update)
      expect(target_store_inital_lever).not.toEqual(lever_update)
      expect(changesOccurred).toEqual(true)
    });

    // it('does not update the current levers when invalid value is entered', () => {});
  });

  describe(Constants.SAVE_LEVERS, () => {
    it('returns the current state of the levers', () => {
      leverStore.dispatch({
        type: Constants.UPDATE_LEVER_VALUE,
        updated_lever:leverData.lever1_update
      })
      leverStore.dispatch({
        type: Constants.UPDATE_LEVER_VALUE,
        updated_lever: leverData.lever5_update
      })
      leverStore.dispatch({
        type: Constants.SAVE_LEVERS,
      })

      expect(leverStore.getState().levers).not.toEqual(leverData.levers.slice(0,5))
      expect(leverStore.getState().levers).toEqual(leverData.updated_levers)
      expect(leverStore.getState().initial_levers).toEqual(leverData.updated_levers)
      expect(leverStore.getState().changesOccurred).toEqual(false)
    });
  });

  describe(Constants.REVERT_LEVERS, () => {
    it('returns the original state of the levers', () => {
      leverStore.dispatch({
        type: Constants.UPDATE_LEVER_VALUE,
        updated_lever: leverData.lever1_update
      })
      leverStore.dispatch({
        type: Constants.UPDATE_LEVER_VALUE,
        updated_lever: leverData.lever5_update
      })
      leverStore.dispatch({
        type: Constants.REVERT_LEVERS,
      })

      expect(leverStore.getState().levers).not.toEqual(leverData.updated_levers)
      expect(leverStore.getState().levers).toEqual(leverData.levers.slice(0,5))
    });
  });
});
