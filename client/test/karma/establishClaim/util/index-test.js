import { expect } from 'chai';
import {
  formattedStationOfJurisdiction,
  validModifiers
} from '../../../../app/establishClaim/util';
import {
  FULL_GRANT,
  FULL_GRANT_MODIFIER_OPTIONS,
  PARTIAL_GRANT_MODIFIER_OPTIONS
} from '../../../../app/establishClaim/constants';

context('establishClaimUtil', () => {
  let result;

  beforeEach(() => {
    result = null;
  });

  context('.formattedStationOfJurisdiction', () => {
    let regionalOfficeCities;

    beforeEach(() => {
      regionalOfficeCities = {
        'RO01': {
          city: 'Boston',
          state: 'MA',
          timezone: 'America/New_York'
        }
      };
    });

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
    it('returns full grant modifiers', () => {
      result = validModifiers([], FULL_GRANT);
      expect(result).to.eql(FULL_GRANT_MODIFIER_OPTIONS);
    });

    it('returns partial grant modifiers', () => {
      result = validModifiers([], 'partial grants!');
      expect(result).to.eql(PARTIAL_GRANT_MODIFIER_OPTIONS);
    });

    it('filters modifiers based on existing end products', () => {
      result = validModifiers(
        [
          {
            'end_product_type_code': '170'
          }
        ],
        'partial grants'
      );

      let modifiers = PARTIAL_GRANT_MODIFIER_OPTIONS.slice();
      // Remove first modifier since it's taken

      modifiers.shift();
      expect(result).to.eql(modifiers);
    });
  });
});
