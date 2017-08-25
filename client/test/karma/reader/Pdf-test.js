import { expect } from 'chai';
import { getInitialAnnotationIconPageCoords } from '../../../app/components/Pdf';
import { pageCoordsOfRootCoords } from '../reader/utils';

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

  describe('getInitialAnnotationIconPageCoords', () => {
    describe('zoom = 1', () => {
      it('centers the icon when the page is contained entirely by the scroll window', () => {
        const pageBox = {
          top: 100,
          bottom: 500,
          left: 200,
          right: 300
        };
        const scrollWindowBox = {
          top: 0,
          bottom: 1000,
          left: 0,
          right: 900
        };

        expect(getInitialAnnotationIconPageCoords(pageBox, scrollWindowBox, 1)).to.deep.equal({
          y: 180,
          x: 30
        });
      });

      it('centers the icon when the scroll window is contained entirely by the page', () => {
        const pageBox = {
          top: -300,
          bottom: 1000,
          left: -500,
          right: 1200
        };
        const scrollWindowBox = {
          top: 0,
          bottom: 900,
          left: 0,
          right: 700
        };

        expect(getInitialAnnotationIconPageCoords(pageBox, scrollWindowBox, 1)).to.deep.equal({
          y: 730,
          x: 830
        });
      });
    });

    describe('zoom = 2', () => {
      it('centers the icon when the page is contained entirely by the scroll window', () => {
        const pageBox = {
          top: 100,
          bottom: 500,
          left: 200,
          right: 300
        };
        const scrollWindowBox = {
          top: 0,
          bottom: 1000,
          left: 0,
          right: 900
        };

        expect(getInitialAnnotationIconPageCoords(pageBox, scrollWindowBox, 2)).to.deep.equal({
          y: 80,
          x: 5
        });
      });

      it('centers the icon when the scroll window is contained entirely by the page', () => {
        const pageBox = {
          top: -300,
          bottom: 1000,
          left: -500,
          right: 1200
        };
        const scrollWindowBox = {
          top: 100,
          bottom: 900,
          left: 100,
          right: 700
        };

        expect(getInitialAnnotationIconPageCoords(pageBox, scrollWindowBox, 2)).to.deep.equal({
          y: 380,
          x: 430
        });
      });
    });
  });
});
