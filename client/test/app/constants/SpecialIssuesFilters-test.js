import specialIssueFunctions from '../../../app/constants/SpecialIssueFilters';

describe('SpecialIssueFilters', () => {
  describe('.unhandledSpecialIssues', () => {
    it('returns all unhandled special issues', () => {
      expect(specialIssueFunctions(true).unhandledSpecialIssues()).toHaveLength(10);
    });
    it('returns all unhandled special issues', () => {
      expect(specialIssueFunctions(false).unhandledSpecialIssues()).toHaveLength(10);
    });
  });
  describe('.regionalSpecialIssues', () => {
    it('returns all regional special issues', () => {
      expect(specialIssueFunctions(true).regionalSpecialIssues()).toHaveLength(9);
    });
    it('returns all regional special issues', () => {
      expect(specialIssueFunctions(false).regionalSpecialIssues()).toHaveLength(9);
    });
  });
  describe('.routedSpecialIssues', () => {
    it('returns all routed special issues', () => {
      expect(specialIssueFunctions(true).routedSpecialIssues()).toHaveLength(6);
    });
    it('returns all routed special issues', () => {
      expect(specialIssueFunctions(false).routedSpecialIssues()).toHaveLength(6);
    });
  });
  describe('.routedOrRegionalSpecialIssues', () => {
    it('returns all routed or regional special issues', () => {
      expect(specialIssueFunctions(true).routedOrRegionalSpecialIssues()).toHaveLength(15);
    });
    it('returns all routed or regional special issues', () => {
      expect(specialIssueFunctions(false).routedOrRegionalSpecialIssues()).toHaveLength(15);
    });
  });
});
