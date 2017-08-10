import { expect } from 'chai';

import * as Actions from '../../../../app/hearings/actions/Dockets';
import * as Constants from '../../../../app/hearings/constants/constants';

describe('.setNotes', () => {
  it('sets notes', () => {
    const hearingIndex = 0;
    const notes = 'this is my note.';
    const date = new Date();
    const expectedAction = {
      type: Constants.SET_NOTES,
      payload: {
        hearingIndex,
        notes,
        date
      }
    };

    expect(Actions.setNotes(hearingIndex, notes, date)).to.eql(expectedAction);
  });
});

describe('.setDisposition', () => {
  it('sets disposition', () => {
    const hearingIndex = 0;
    const disposition = 'no_show';
    const date = new Date();
    const expectedAction = {
      type: Constants.SET_DISPOSITION,
      payload: {
        hearingIndex,
        disposition,
        date
      }
    };

    expect(Actions.setDisposition(hearingIndex, disposition, date)).to.eql(expectedAction);
  });
});

describe('.setHoldOpen', () => {
  it('sets hold open', () => {
    const hearingIndex = 0;
    const holdOpen = 60;
    const date = new Date();
    const expectedAction = {
      type: Constants.SET_HOLD_OPEN,
      payload: {
        hearingIndex,
        holdOpen,
        date
      }
    };

    expect(Actions.setHoldOpen(hearingIndex, holdOpen, date)).to.eql(expectedAction);
  });
});

describe('.setAod', () => {
  it('sets AOD', () => {
    const hearingIndex = 0;
    const aod = 'filed';
    const date = new Date();
    const expectedAction = {
      type: Constants.SET_AOD,
      payload: {
        hearingIndex,
        aod,
        date
      }
    };

    expect(Actions.setAod(hearingIndex, aod, date)).to.eql(expectedAction);
  });
});

describe('.setTranscriptRequested', () => {
  it('sets transcript requested', () => {
    const hearingIndex = 0;
    const transcriptRequested = true;
    const date = new Date();
    const expectedAction = {
      type: Constants.SET_TRANSCRIPT_REQUESTED,
      payload: {
        hearingIndex,
        transcriptRequested,
        date
      }
    };

    expect(Actions.setTranscriptRequested(hearingIndex, transcriptRequested, date)).to.eql(expectedAction);
  });
});
