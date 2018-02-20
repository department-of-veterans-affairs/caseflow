import { expect } from 'chai';
import { currentIssues, priorIssues } from '../../../../app/hearings/util/IssuesUtil';

describe('IssuesUtil', () => {

  const issues = {
    1: {
      disposition: 'Remanded',
      from_vacols: true
    },
    2: {
      disposition: 'Granted',
      from_vacols: true
    },
    3: {
      disposition: null,
      from_vacols: true
    },
    4: {
      _destroy: true,
      from_vacols: true
    },
    5: {
      disposition: 'Remanded',
      from_vacols: false
    }
  };

  context('.currentIssues', () => {

    const currentIssuesFiltered = {
      1: {
        disposition: 'Remanded',
        from_vacols: true
      },
      3: {
        disposition: null,
        from_vacols: true
      },
      5: {
        disposition: 'Remanded',
        from_vacols: false
      }
    };

    it('returns current issues', () => {
      expect(currentIssues(issues)).to.deep.equal(currentIssuesFiltered);
    });
  });

  context('.priorIssues', () => {

    const priorIssuesFiltered = {
      2: {
        disposition: 'Granted',
        from_vacols: true
      }
    };

    it('returns prior issues', () => {
      expect(priorIssues(issues)).to.deep.equal(priorIssuesFiltered);
    });
  });
});
