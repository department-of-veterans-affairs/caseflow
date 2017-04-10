import { expect } from 'chai';
import { getSpecialIssuesInitialState } from
  '../../../app/establishClaim/reducers/specialIssues';

describe('SpecialIssuesReducer', () => {
  context('.getSpecialIssuesInitialState', () => {
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

      expect(keys).to.include('vamc');
      expect(keys.length).to.eq(25);
    });

    it('defaults to false', () => {
      expect(initialState.vamc).to.eq(false);
    });

    it('allows override based on initial values', () => {
      expect(initialState.mustardGas).to.eq(true);
    });
  });
});
