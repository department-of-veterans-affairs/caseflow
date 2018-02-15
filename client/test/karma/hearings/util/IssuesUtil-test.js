import { expect } from 'chai';
import { currentIssues, priorIssues } from '../../../../app/hearings/util/IssuesUtil';

describe('IssuesUtil', () => {

  const issues = {
    1: {
      disposition: 'Remanded'
    },
    2: {
      disposition: 'Granted'
    },
    3: {
      disposition: null
    },
    4: {
      _destroy: true
    }
  };

  context('.currentIssues', () => {

    const currentIssuesFiltered = {
      1: {
        disposition: 'Remanded'
      },
      3: {
        disposition: null
      }
    };

    it('returns current issues', () => {
      expect(currentIssues(issues)).to.deep.equal(currentIssuesFiltered);
    });
  });

  context('.priorIssues', () => {

    const priorIssuesFiltered = {
      2: {
        disposition: 'Granted'
      }
    };

    it('returns prior issues', () => {
      expect(priorIssues(issues)).to.deep.equal(priorIssuesFiltered);
    });
  });
});
