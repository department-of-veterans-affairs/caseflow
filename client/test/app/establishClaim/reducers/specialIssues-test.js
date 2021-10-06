import { getSpecialIssuesInitialState } from
  '../../../../app/establishClaim/reducers/specialIssues';

describe('SpecialIssuesReducer', () => {
  describe('.getSpecialIssuesInitialState', () => {
    let initialState, props;

    beforeEach(() => {
      /* eslint-disable camelcase */
      props = {
        task: {
          appeal: {
            mustard_gas: true
          }
        }
      };
      /* eslint-disable camelcase */

      initialState = getSpecialIssuesInitialState(props);
    });

    it('adds all special issue keys', () => {
      let keys = Object.keys(initialState);

      expect(keys).toEqual(expect.arrayContaining(['vamc']));
      expect(keys.length).toBe(25);
    });

    it('defaults to false', () => {
      expect(initialState.vamc).toBe(false);
    });

    it('allows override based on initial values', () => {
      expect(initialState.mustardGas).toBe(true);
    });
  });
});
