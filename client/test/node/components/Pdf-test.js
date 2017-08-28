import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import { Pdf } from '../../../app/components/Pdf';
import sinon from 'sinon';
import _ from 'lodash';

import PdfJsStub from '../../helpers/PdfJsStub';
import { asyncTest, pause } from '../../helpers/AsyncTests';

import { documents } from '../../data/documents';

/* eslint-disable no-unused-expressions */
describe('Pdf', () => {
  let pdfId = 'pdf';

  // Note, these tests use shallow rather than shallow.
  // In order to get that working, we must stub out
  // our endpoints in PDFJS and PDFJSAnnotate.
  // To approach reality, our stubbed out versions
  // also add divs representing PDF 'pages' to the dom.

  /* eslint-disable max-statements */
  context('shallow and mock out pdfjs', () => {
    let wrapper;
    let onPageChange;

    beforeEach(() => {
      onPageChange = sinon.spy();

      wrapper = shallow(<Pdf
        comments={[]}
        documentId={documents[0].id}
        file="test.pdf"
        id={pdfId}
        setPdfReadyToShow={_.noop}
        setPageCoordBounds={_.noop}
        pdfWorker="noworker"
        scale={1}
        onPageChange={onPageChange}
      />, { attachTo: document.getElementById('app') });
    });

    afterEach(() => {
      wrapper.detach();
      PdfJsStub.afterEach();
    });

    describe('onPageChange', () => {
      const page = 1;

      context('when scale is 1', () => {
        const scale = 1;

        it('calls onPageChange with 1', () => {
          wrapper.setProps({ scale });
          wrapper.instance().onPageChange(page);
          expect(onPageChange.calledWith(page, PdfJsStub.numPages, scale)).to.equal(true);
        });
      });

      context('when scale is 2', () => {
        const scale = 2;

        it('calls onPageChange with 2', () => {
          wrapper.setProps({ scale });
          wrapper.instance().onPageChange(page);
          expect(onPageChange.calledWith(page, PdfJsStub.numPages, scale)).to.equal(true);
        });
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
});

/* eslint-enable no-unused-expressions */
