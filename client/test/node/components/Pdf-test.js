import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { Pdf, getInitialAnnotationIconPageCoords } from '../../../app/components/Pdf';
import sinon from 'sinon';
import _ from 'lodash';

import PdfJsStub from '../../helpers/PdfJsStub';
import { asyncTest, pause } from '../../helpers/AsyncTests';

import { documents } from '../../data/documents';

/* eslint-disable no-unused-expressions */
describe('Pdf', () => {
  let pdfId = 'pdf';

  // Note, these tests use mount rather than shallow.
  // In order to get that working, we must stub out
  // our endpoints in PDFJS and PDFJSAnnotate.
  // To approach reality, our stubbed out versions
  // also add divs representing PDF 'pages' to the dom.

  /* eslint-disable max-statements */
  context('mount and mock out pdfjs', () => {
    let wrapper;
    let onPageChange;

    beforeEach(() => {
      onPageChange = sinon.spy();

      PdfJsStub.beforeEach();

      wrapper = mount(<Pdf
        comments={[]}
        documentId={documents[0].id}
        file="test.pdf"
        id={pdfId}
        setPdfReadyToShow={_.noop}
        pdfWorker="noworker"
        scale={1}
        onPageChange={onPageChange}
      />, { attachTo: document.getElementById('app') });
    });

    afterEach(() => {
      wrapper.detach();
      PdfJsStub.afterEach();
    });

    context('.render', () => {
      it('renders the staging div', () => {
        expect(wrapper.find('.cf-pdf-pdfjs-container')).
          to.have.length(PdfJsStub.numPages);
      });
    });

    context('.setUppdf', () => {
      context('onPageChange set', () => {
        it(`calls onPageChange with 1 and ${PdfJsStub.numPages}`, asyncTest(async() => {
          wrapper.instance().setUpPdf('test.pdf');
          await pause();

          expect(onPageChange.calledWith(1, PdfJsStub.numPages, sinon.match.number)).to.be.true;
        }));
      });
    });

    context('.componentWillReceiveProps', () => {
      let draw;

      beforeEach(() => {
        draw = sinon.spy(wrapper.instance(), 'setUpPdf');
      });

      context('when file is set', () => {
        it('creates a new page', () => {
          expect(draw.callCount).to.equal(0);
          wrapper.setProps({ file: 'newFile' });
          expect(draw.callCount).to.equal(1);
        });
      });

      context('when id is set', () => {
        it('pages are not redrawn (no-op)', () => {
          wrapper.setProps({ id: 'newId' });
          expect(draw.callCount).to.equal(0);
        });
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

/* eslint-enable no-unused-expressions */
