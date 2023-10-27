import React from 'react';
import { shallow } from 'enzyme';
import { pageCoordsOfRootCoords } from '../../../app/reader/utils';
import { Pdf } from '../../../app/reader/Pdf';
import PdfFile from '../../../app/reader/PdfFile';

const FILE_URLS = [
  '/document/1/pdf',
  '/document/2/pdf',
  '/document/3/pdf',
  '/document/4/pdf',
];

describe('Pdf', () => {
  describe('Prefetch Feature toggle', () => {
    it('creates previous, current, and next PdfFile components when it is disabled', () => {
      // Set up props with three document urls and prefetchDisabled OFF
      const props = {
        prefetchFiles: [FILE_URLS[0], FILE_URLS[2]],
        file: FILE_URLS[1],
        featureToggles: {
          prefetchDisabled: false
        }
      };
      // Render the Pdf component shallowly
      const component = shallow(<Pdf {...props} />);
      // Select all PdfFile components that were created and pull their 'file' prop
      const fileUrls = component.find(PdfFile).map((node) => node.prop('file'));

      // Expect Pdf component to create three PdfFile components
      expect(component.find(PdfFile).length).toBe(3);
      // Expect the file urls of each PdfFile component to match the prefetch files and current file
      expect(fileUrls).toEqual([...props.prefetchFiles, props.file]);
    });
    it('creates current PdfFile component when it is enabled', () => {
      // Set up props with three document urls and prefetchDisabled ON
      const props = {
        prefetchFiles: [FILE_URLS[0], FILE_URLS[2]],
        file: FILE_URLS[3],
        featureToggles: {
          prefetchDisabled: true
        }
      };
      // Render the Pdf component shallowly
      const component = shallow(<Pdf {...props} />);
      // Select all PdfFile components that were created and pull their 'file' prop
      const fileUrls = component.find(PdfFile).map((node) => node.prop('file'));

      // Expect Pdf component to create three PdfFile components
      expect(component.find(PdfFile).length).toBe(1);
      // Expect the file url of the PdfFile component to match the current file
      expect(fileUrls).toEqual([props.file]);
    });
  });

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

      expect(pageCoordsOfRootCoords(pageCoords, pageBoundingBox, 2)).toEqual({
        x: 25,
        y: 90
      });
    });
  });
});
