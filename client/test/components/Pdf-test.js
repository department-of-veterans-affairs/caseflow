import React from 'react';
import { expect, assert } from 'chai';
import { mount } from 'enzyme';
import Pdf from '../../app/components/Pdf';
import sinon from 'sinon';

import PdfJsStub from '../helpers/PdfJsStub';

import { documents } from '../data/documents';
import { annotations } from '../data/annotations';

/* eslint-disable no-unused-expressions */
describe('Pdf', () => {
  let pdfId = "pdf";

  // Note, these tests use mount rather than shallow.
  // In order to get that working, we must stub out
  // our endpoints in PDFJS and PDFJSAnnotate.
  // To appraoch reality, our stubbed out versions
  // also add divs representing PDF 'pages' to the dom.

  /* eslint-disable max-statements */
  context('mount and mock out pdfjs', () => {
    let wrapper;

    beforeEach(() => {
      PdfJsStub.beforeEach();

      wrapper = mount(<Pdf
        comments={[]}
        documentId={documents[0].id}
        file="test.pdf"
        id={pdfId}
        pdfWorker="noworker"
        scale={1}
      />, { attachTo: document.getElementById('app') });
    });

    afterEach(() => {
      wrapper.detach();
      PdfJsStub.afterEach();
    });

    context('.render', () => {
      it(`renders the staging div`, () => {
        expect(wrapper.find('.cf-pdf-pdfjs-container')).to.have.length(PdfJsStub.numPages);
      });
    });

    context('.setuppdf', () => {
      context('onPageChange set', () => {
        let onPageChange;

        beforeEach(() => {
          onPageChange = sinon.spy();
          wrapper.setProps({
            onPageChange
          });
        });

        it(`calls onPageChange with 1 and ${PdfJsStub.numPages}`, (done) => {
          wrapper.instance().setupPdf("test.pdf").
            then(() => {
              expect(onPageChange.calledWith(1, PdfJsStub.numPages)).to.be.true;
              done();
            });
        });
      });
    });

    context('.componentWillReceiveProps', () => {
      let draw;

      beforeEach(() => {
        draw = sinon.spy(wrapper.instance(), 'setupPdf');
      });

      context('when file is set', () => {
        it('creates a new page', () => {
          expect(draw.callCount).to.equal(0);
          wrapper.setProps({ file: 'newFile' });
          expect(draw.callCount).to.equal(1);
        });
      });

      context('when scale is set', () => {
        it('creates a new page', () => {
          expect(draw.callCount).to.equal(0);
          wrapper.setProps({ scale: 2 });
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

  /* eslint-enable max-statements */
});

/* eslint-enable no-unused-expressions */
