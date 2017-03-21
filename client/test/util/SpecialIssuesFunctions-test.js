import { expect } from 'chai';
import specialIssueFunctions from '../../app/util/SpecialIssueFunctions';

describe('SpecialIssueFunctions', () => {
  context('.unhandledSpecialIssues', () => {
    it('returns all unhandled special issues', () => {
      expect(specialIssueFunctions.unhandledSpecialIssues()).have.lengthOf(11);
    });
  });
  context('.regionalSpecialIssues', () => {
    it('returns all regional special issues', () => {
      expect(specialIssueFunctions.regionalSpecialIssues()).have.lengthOf(8);
    });
  });
  context('.routedSpecialIssues', () => {
    it('returns all routed special issues', () => {
      expect(specialIssueFunctions.routedSpecialIssues()).have.lengthOf(6);
    });
  });
  context('.routedOrRegionalSpecialIssues', () => {
    it('returns all routed or regional special issues', () => {
      expect(specialIssueFunctions.routedOrRegionalSpecialIssues()).have.lengthOf(14);
    });
  });
});
