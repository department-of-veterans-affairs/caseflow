import { expect } from 'chai';

import * as Actions from '../../../../app/hearings/actions/Dockets';
import * as Constants from '../../../../app/hearings/constants/constants';
import { CATEGORIES, ACTIONS, debounceMs } from '../../../../app/hearings/analytics';

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
      },
      meta: {
        analytics: {
          category: CATEGORIES.DAILY_DOCKET_PAGE,
          debounceMs
        }
      }
    };

    expect(Actions.setNotes(hearingIndex, notes, date)).to.deep.equal(expectedAction);
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
      },
      meta: {
        analytics: {
          category: CATEGORIES.DAILY_DOCKET_PAGE,
          action: ACTIONS.DISPOSITION_SELECTED,
          label: disposition
        }
      }
    };

    expect(Actions.setDisposition(hearingIndex, disposition, date)).to.deep.equal(expectedAction);
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

    expect(Actions.setHoldOpen(hearingIndex, holdOpen, date)).to.deep.equal(expectedAction);
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
      },
      meta: {
        analytics: {
          category: CATEGORIES.DAILY_DOCKET_PAGE,
          action: ACTIONS.AOD_SELECTED,
          label: aod
        }
      }
    };

    expect(Actions.setAod(hearingIndex, aod, date)).to.deep.equal(expectedAction);
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
      },
      meta: {
        analytics: {
          category: CATEGORIES.DAILY_DOCKET_PAGE,
          action: ACTIONS.TRANSCRIPT_REQUESTED,
          label: transcriptRequested ? 'checked' : 'unchecked'
        }
      }
    };

    expect(Actions.setTranscriptRequested(hearingIndex, transcriptRequested, date)).to.deep.equal(expectedAction);
  });
});

describe('.onMilitaryServiceChange', () => {
  it('sets military service text', () => {

    const militaryService = 'this is a worksheet periods text';
    const expectedAction = {
      type: Constants.SET_MILITARY_SERVICE,
      payload: {
        militaryService
      },
      meta: {
        analytics: {
          category: CATEGORIES.HEARING_WORKSHEET_PAGE,
          debounceMs
        }
      }
    };

    expect(Actions.onMilitaryServiceChange(militaryService)).to.deep.equal(expectedAction);
  });
});

describe('.onSummaryChange', () => {
  it('sets summary text', () => {

    const summary = 'this is a worksheet summary text';
    const expectedAction = {
      type: Constants.SET_SUMMARY,
      payload: {
        summary
      },
      meta: {
        analytics: {
          category: CATEGORIES.HEARING_WORKSHEET_PAGE,
          debounceMs
        }
      }
    };

    expect(Actions.onSummaryChange(summary)).to.deep.equal(expectedAction);
  });
});
