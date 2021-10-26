import pdfViewerReducer from '../../../../app/reader/PdfViewer/PdfViewerReducer';
import * as Constants from '../../../../app/reader/PdfViewer/actionTypes';

/* eslint-disable no-undefined */

describe('Reader reducer', () => {

  const reduceActions = (actions, state) => actions.reduce(pdfViewerReducer, pdfViewerReducer(state, {}));

  describe(Constants.SET_ZOOM_LEVEL, () => {
    it('stores scale value when received', () => {
      const scale = 0.5;
      const state = reduceActions([
        {
          type: Constants.SET_ZOOM_LEVEL,
          payload: {
            scale
          }
        }
      ]);

      expect(state.scale).toEqual(scale);
    });

    it('shows undefined scale when nothing is passed', () => {
      const state = reduceActions([
        {
          type: Constants.SET_ZOOM_LEVEL,
          payload: { }
        }
      ]);

      expect(state.scale).toBeUndefined();
    });
  });

  describe(Constants.SET_LOADED_APPEAL_ID, () => {
    it('updates loadedAppealId object when received', () => {
      const vacolsId = 1;
      const state = reduceActions([
        {
          type: Constants.SET_LOADED_APPEAL_ID,
          payload: {
            vacolsId
          }
        }
      ]);

      expect(state.loadedAppealId).toEqual(vacolsId);
    });

    it('shows undefined loadedAppealId object when nothing is passed', () => {
      const state = reduceActions([
        {
          type: Constants.SET_LOADED_APPEAL_ID,
          payload: { }
        }
      ]);

      expect(state.loadedAppealId).toBeUndefined();
    });
  });

  describe(Constants.RECEIVE_APPEAL_DETAILS_FAILURE, () => {
    const getContext = () => {
      const stateAfterFetchFailure = {
        didLoadAppealFail: false
      };

      return {
        stateAfterFetchFailure: reduceActions([
          {
            type: Constants.RECEIVE_APPEAL_DETAILS_FAILURE,
            payload: {
              failedToLoad: true
            }
          },
          stateAfterFetchFailure])
      };
    };

    it('shows an error message when the request fails', () => {
      const { stateAfterFetchFailure } = getContext();

      expect(stateAfterFetchFailure.didLoadAppealFail).toBe(true);
    });
  });
});
