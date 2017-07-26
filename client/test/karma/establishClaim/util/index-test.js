import { expect } from 'chai';
import {
  formattedStationOfJurisdiction,
  validModifiers,
  getSpecialIssuesRegionalOffice,
  getSpecialIssuesRegionalOfficeCode,
  getSpecialIssuesEmail
} from '../../../../app/establishClaim/util';
import { MODIFIER_OPTIONS } from '../../../../app/establishClaim/constants';

context('establishClaimUtil', () => {
  let result;
  const regionalOfficeCities = {
    RO01: {
      city: 'Boston',
      state: 'MA',
      timezone: 'America/New_York'
    },
    RO84: {
      city: 'Philadelphia COWAC',
      state: 'PA',
      timezone: 'America/New_York'
    }
  };

  beforeEach(() => {
    result = null;
  });

  context('.formattedStationOfJurisdiction', () => {

    it('handles special issues with a unique SOJ', () => {
      result = formattedStationOfJurisdiction(
        '311',
        'doesnt-matter',
        regionalOfficeCities
      );
      expect(result).to.eq('311 - Pittsburgh, PA');
    });

    it('uniqely handles ARC (397)', () => {
      result = formattedStationOfJurisdiction(
        '397',
        'doesnt-matter',
        regionalOfficeCities
      );
      expect(result).to.eq('397 - ARC');
    });

    it('falls back to using regional office information', () => {
      result = formattedStationOfJurisdiction(
        '103',
        'RO01',
        regionalOfficeCities
      );
      expect(result).to.eq('103 - Boston, MA');
    });
  });

  context('.validModifiers', () => {
    it('returns modifiers', () => {
      result = validModifiers([]);
      expect(result).to.eql(MODIFIER_OPTIONS);
    });

    it('filters modifiers based on existing end products', () => {
      result = validModifiers(
        [
          {
            end_product_type_code: '070'
          }
        ],
        'partial grants'
      );

      let modifiers = MODIFIER_OPTIONS.slice();
      // Remove first modifier since it's taken

      modifiers.shift();
      expect(result).to.eql(modifiers);
    });
  });

  context('.getSpecialIssuesRegionalOfficeCode', () => {
    const regionalOfficeKey = 'RO18';

    it('when a PMC special issue', () => {
      result = getSpecialIssuesRegionalOfficeCode('PMC', regionalOfficeKey);
      expect(result).to.eql('RO81');
    });
    it('when a COWC special issue', () => {
      result = getSpecialIssuesRegionalOfficeCode('COWC', regionalOfficeKey);
      expect(result).to.eql('RO84');
    });

    it('when an education special issue', () => {
      result = getSpecialIssuesRegionalOfficeCode('education', regionalOfficeKey);
      expect(result).to.eql('RO91');
    });

    it('when no special issue regional office', () => {
      result = getSpecialIssuesRegionalOfficeCode(null, regionalOfficeKey);
      expect(result).to.eql(null);
    });
  });

  context('.getSpecialIssuesRegionalOffice', () => {
    it('returns a human readable version of the special regional office', () => {
      result = getSpecialIssuesRegionalOffice('COWC', 'RO19', regionalOfficeCities);
      expect(result).to.eql('RO84 - Philadelphia COWAC, PA');
    });
  });

  context('.getSpecialIssuesEmail', () => {
    const regionalOfficeKey = 'RO18';

    it('when a PMC special issue', () => {
      result = getSpecialIssuesEmail('PMC', regionalOfficeKey);
      expect(result).to.eql(
        ['matthew.wright1@va.gov', 'andrea.gaetano@va.gov', 'PensionCenter.vbaphi@va.gov']
      );
    });

    it('when a COWC special issue', () => {
      result = getSpecialIssuesEmail('COWC', regionalOfficeKey);
      expect(result).to.eql(
        ['cowc.vbaphi@va.gov', 'Sohail.Atoum@va.gov']
      );
    });

    it('when an education special issue', () => {
      result = getSpecialIssuesEmail('education', regionalOfficeKey);
      expect(result).to.eql(
        ['anthony.mazur@va.gov', 'edu.vbabuf@va.gov']
      );
    });

    it('when already a specific email address', () => {
      const specialIssueEmail = ['Travis.Richardson@va.gov'];

      result = getSpecialIssuesEmail(['Travis.Richardson@va.gov'], regionalOfficeKey);
      expect(result).to.eql(specialIssueEmail);
    });
  });
});
