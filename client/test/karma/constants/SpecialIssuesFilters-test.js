import { expect } from 'chai';
import specialIssueFunctions from '../../../app/constants/SpecialIssueFilters';

describe('SpecialIssueFilters', () => {
  context('.unhandledSpecialIssues', () => {
    it('returns all unhandled special issues', () => {
      expect(specialIssueFunctions(true).unhandledSpecialIssues()).have.lengthOf(10);
    });
    it('returns all unhandled special issues', () => {
      expect(specialIssueFunctions(false).unhandledSpecialIssues()).have.lengthOf(10);
    });
  });
  context('.regionalSpecialIssues', () => {
    it('returns all regional special issues', () => {
      expect(specialIssueFunctions(true).regionalSpecialIssues()).have.lengthOf(9);
    });
    it('returns all regional special issues', () => {
      expect(specialIssueFunctions(false).regionalSpecialIssues()).have.lengthOf(9);
    });
  });
  context('.routedSpecialIssues', () => {
    it('returns all routed special issues', () => {
      expect(specialIssueFunctions(true).routedSpecialIssues()).have.lengthOf(6);
    });
    it('returns all routed special issues', () => {
      expect(specialIssueFunctions(false).routedSpecialIssues()).have.lengthOf(6);
    });
  });
  context('.routedOrRegionalSpecialIssues', () => {
    it('returns all routed or regional special issues', () => {
      expect(specialIssueFunctions(true).routedOrRegionalSpecialIssues()).have.lengthOf(15);
    });
    it('returns all routed or regional special issues', () => {
      expect(specialIssueFunctions(false).routedOrRegionalSpecialIssues()).have.lengthOf(15);
    });
  });
});
