import { expect } from 'chai';
import { getInitialAnnotationIconPageCoords } from '../../../app/reader/Pdf';
import { pageCoordsOfRootCoords } from '../../../app/reader/utils';

describe('Pdf', () => {
  describe('pageCoordsOfRootCoords', () => {
    it('converts from root coords to page coords', () => {
      const pageCoords = {
        x: 100,
        y: 200
      };
      const pageBoundingBox = {
        left: 50,
        top: 20
      };

      expect(pageCoordsOfRootCoords(pageCoords, pageBoundingBox, 2)).to.deep.equal({
        x: 25,
        y: 90
      });
    });
  });
});
