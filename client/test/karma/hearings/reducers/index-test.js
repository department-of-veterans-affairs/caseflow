import { expect } from 'chai';
import * as Hearings from '../../../../app/hearings/reducers/index';
import * as Constants from '../../../../app/hearings/constants/constants';

/* eslint max-statements: ["error", 10, { "ignoreTopLevelFunctions": true }]*/
describe('hearingsReducer', () => {
  let initialState;

  beforeEach(() => {
    initialState = Hearings.mapDataToInitialState({
      dockets: {
        '2017-08-10': {
          hearings_array: {
            0: {}
          }
        }
      },
      worksheet: {
        streams: {
          8873: {
            issues: {
              66: {
              }
            }
          }
        }
      }
    });
  });

  context(Constants.SET_REPNAME, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_REPNAME,
        payload: {
          repName: 'John Smith'
        }
      });
    });

    it('sets worksheet contentions', () => {
      expect(state.worksheet.repName).to.deep.equal('John Smith');
    });
  });


  context(Constants.SET_WITNESS, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_WITNESS,
        payload: {
          witness: 'Jane Doe'
        }
      });
    });

    it('sets worksheet contentions', () => {
      expect(state.worksheet.witness).to.deep.equal('Jane Doe');
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_array: { 0: { notes: 'this is my note',
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_array: { 0: { disposition: 'no_show',
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_array: { 0: { hold_open: 60,
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_array: { 0: { aod: 'filed',
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_array: { 0: { addon: true,
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
      expect(state.dockets).to.deep.equal({ '2017-08-10': { hearings_array: { 0: { transcript_requested: true,
        edited: true } } } });
    });
  });

  context(Constants.SET_DESCRIPTION, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_DESCRIPTION,
        payload: {
          description: 'Elbow Arthritis',
          issueId: 66 }
      });
    });

    it('sets worksheet issue description', () => {
      expect(state.worksheet.streams[8873].issues).to.deep.equal({
        66: { description: 'Elbow Arthritis' }
      }
     );
    });
  });

  context(Constants.SET_REOPEN, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_REOPEN,
        payload: { reopen: true,
          issueId: 66 }
      });
    });

    it('sets worksheet issue reopen', () => {
      expect(state.worksheet.streams[8873].issues).to.deep.equal({
        66: { reopen: true }
      }
     );
    });
  });

  context(Constants.SET_ALLOW, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_ALLOW,
        payload: { allow: true,
          issueId: 66 }
      });
    });

    it('sets worksheet issue allow', () => {
      expect(state.worksheet.streams[8873].issues).to.deep.equal({
        66: { allow: true }
      }
     );
    });
  });

  context(Constants.SET_DENY, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_DENY,
        payload: { deny: true,
          issueId: 66 }
      });
    });

    it('sets worksheet issue deny', () => {
      expect(state.worksheet.streams[8873].issues).to.deep.equal({
        66: { deny: true }
      }
     );
    });
  });

  context(Constants.SET_REMAND, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_REMAND,
        payload: { remand: true,
          issueId: 66 }
      });
    });

    it('sets worksheet issue remand', () => {
      expect(state.worksheet.streams[8873].issues).to.deep.equal({
        66: { remand: true }
      }
     );
    });
  });

  context(Constants.SET_DISMISS, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_DISMISS,
        payload: { dismiss: true,
          issueId: 66 }
      });
    });

    it('sets worksheet issue dismiss', () => {
      expect(state.worksheet.streams[8873].issues).to.deep.equal({
        66: { dismiss: true }
      }
     );
    });
  });

  context(Constants.SET_VHA, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_VHA,
        payload: { vha: true,
          issueId: 66 }
      });
    });

    it('sets worksheet issue vha', () => {
      expect(state.worksheet.streams[8873].issues).to.deep.equal({
        66: { vha: true }
      }
     );
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

  context(Constants.SET_MILITARY_SERVICE, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_MILITARY_SERVICE,
        payload: {
          militaryService: 'filled'
        }
      });
    });

    it('sets worksheet military service', () => {
      expect(state.worksheet.military_service).to.deep.equal('filled');
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

  context(Constants.SET_COMMENTS_FOR_ATTORNEY, () => {
    let state;

    beforeEach(() => {
      state = Hearings.hearingsReducers(initialState, {
        type: Constants.SET_COMMENTS_FOR_ATTORNEY,
        payload: {
          commentsForAttorney: 'filled'
        }
      });
    });

    it('sets worksheet comments for attorney', () => {
      expect(state.worksheet.comments_for_attorney).to.deep.equal('filled');
    });
  });
});
