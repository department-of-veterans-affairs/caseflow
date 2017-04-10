import { expect } from 'chai';
import SpecialIssueReducer, { getSpecialIssuesInitialState } from '../../../app/establishClaim/reducers/specialIssues';

describe('SpecialIssuesReducer', () => {
  context('.getSpecialIssuesInitialState', () => {
    let initialState, props;

    beforeEach(() => {
      props = {
        task: {
          appeal: {
            mustard_gas: true
          }
        }
      };
      initialState = getSpecialIssuesInitialState(props);
    });

    it('adds all special issue keys', () => {
      let keys = Object.keys(initialState);
      expect(keys).to.include('vamc');
      expect(keys.length).to.eq(25);
    });

    it('defaults to false', () => {
      expect(initialState.vamc).to.be.false;
    });

    it('allows override based on initial values', () => {
      expect(initialState.mustardGas).to.be.true;
    });
  });
});
