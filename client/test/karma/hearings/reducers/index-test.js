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
      },
      worksheet: {
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { notes: 'this is my note',
        edited: true } } } });
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { disposition: 'no_show',
        edited: true } } } });
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { hold_open: 60,
        edited: true } } } });
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { aod: 'filed',
        edited: true } } } });
    });
  });

  context(Constants.SET_ADD_ON, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_ADD_ON,
        payload: {
          hearingIndex: 0,
          addOn: true,
          date: '2017-08-10'
        }
      });
    });

    it('sets addon', () => {
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { addon: true,
        edited: true } } } });
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_hash: { 0: { transcript_requested: true,
        edited: true } } } });
    });
  });

  context(Constants.SET_DESCRIPTIONS, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_DESCRIPTIONS,
        payload: {
          description: 'filled'
        }
      });
    });

    it('sets worksheet issue description', () => {
      expect(state.worksheet.issue.description).to.deep.equal('filled');
    });
  });

  context(Constants.SET_CONTENTIONS, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_CONTENTIONS,
        payload: {
          contentions: 'filled'
        }
      });
    });

    it('sets worksheet contentions', () => {
      expect(state.worksheet.contentions).to.deep.equal('filled');
    });
  });

  context(Constants.SET_PERIODS, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_PERIODS,
        payload: {
          periods: 'filled'
        }
      });
    });

    it('sets worksheet periods', () => {
      expect(state.worksheet.periods).to.deep.equal('filled');
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

    it('sets evidences', () => {
      expect(state.worksheet.evidence).to.deep.equal('filled');
    });
  });

  context(Constants.SET_COMMENTS, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_COMMENTS,
        payload: {
          comments: 'filled'
        }
      });
    });

    it('sets worksheet comments', () => {
      expect(state.worksheet.comments).to.deep.equal('filled');
    });
  });
});
