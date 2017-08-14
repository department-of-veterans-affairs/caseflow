import { expect } from 'chai';
import * as Hearings from '../../../../app/hearings/reducers/index';
import * as Constants from '../../../../app/hearings/constants/constants';

describe('hearingsReducer', () => {
  let initialState;

  beforeEach(() => {
    initialState = Hearings.mapDataToInitialState({
      dockets: {
        '2017-08-10': {
          hearings_hash: {
            0: {}
          }
        }
      }
    });
  });

  context(Constants.SET_NOTES, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_NOTES,
        payload: {
          hearingIndex: 0,
          notes: 'this is my note',
          date: '2017-08-10'
        }
      });
    });

    it('sets notes', () => {
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { notes: 'this is my note' } } } });
    });
  });

  context(Constants.SET_DISPOSITION, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_DISPOSITION,
        payload: {
          hearingIndex: 0,
          disposition: 'no_show',
          date: '2017-08-10'
        }
      });
    });

    it('sets disposition', () => {
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { disposition: 'no_show' } } } });
    });
  });

  context(Constants.SET_HOLD_OPEN, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_HOLD_OPEN,
        payload: {
          hearingIndex: 0,
          holdOpen: 60,
          date: '2017-08-10'
        }
      });
    });

    it('sets hold open', () => {
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { hold_open: 60 } } } });
    });
  });

  context(Constants.SET_AOD, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_AOD,
        payload: {
          hearingIndex: 0,
          aod: 'filed',
          date: '2017-08-10'
        }
      });
    });

    it('sets aod', () => {
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { aod: 'filed' } } } });
    });
  });

  context(Constants.SET_TRANSCRIPT_REQUESTED, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_TRANSCRIPT_REQUESTED,
        payload: {
          hearingIndex: 0,
          transcriptRequested: true,
          date: '2017-08-10'
        }
      });
    });

    it('sets transcript requested', () => {
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { transcript_requested: true } } } });
    });
  });

  context(Constants.SET_CONTENTIONS, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_CONTENTIONS,
        payload: {
          contentions:
        }
      });
    });

    it('sets contentions', () => {
      expect(state.worksheet).to.deep.equal({   worksheet: { contentions: 'this is a contention text' } });
    });
  });

  context(Constants.SET_WORKSHEET_PERIODS, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_WORKSHEET_PERIODS,
        payload: {
          worksheetPeriods: 'filled'
        }
      });
    });

    it('sets contentions', () => {
      expect(state.worksheet).to.deep.equal({   worksheet: { worksheetPeriods: 'this is a worksheet periods text' } });
    });
  });

  context(Constants.SET_EVIDENCE, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_EVIDENCE,
        payload: {
          evidence: 'filled'
        }
      });
    });

    it('sets contentions', () => {
      expect(state.worksheet).to.deep.equal({   worksheet: { evidence: 'this is a evidence text' } });
    });
  });

  context(Constants.SET_WORKSHEET_COMMENTS, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_WORKSHEET_COMMENTS,
        payload: {
          worksheetComments: 'filled'
        }
      });
    });

    it('sets contentions', () => {
      expect(state.worksheet).to.deep.equal({   worksheet: { worksheetComments: 'this is a worksheet comments text' } });
    });
  });
});