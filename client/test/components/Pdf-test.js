import React from 'react';
import { expect, assert } from 'chai';
import { mount } from 'enzyme';
import Pdf from '../../app/components/Pdf';
import sinon from 'sinon';

import PdfJsStub from '../helpers/PdfJsStub';

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
        documentId={1}
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
        expect(wrapper.find(`#${pdfId}`)).to.have.length(1);
      });
    });

    context('.setuppdf', () => {
      it('calls createPages and renderPage', (done) => {
        let renderPageSpy = sinon.spy(wrapper.instance(), 'renderPage');
        let createPageSpy = sinon.spy(wrapper.instance(), 'createPages');

        wrapper.instance().setupPdf("test.pdf").
          then(() => {
            expect(renderPageSpy.callCount).to.equal(1);
            expect(createPageSpy.callCount).to.equal(1);
            done();
          });
      });

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

    context('.createPages', () => {
      // reset any calls from mounting
      beforeEach(() => {
        PdfJsStub.pdfjsCreatePage.resetHistory();
      });

      it(`calls PDFJS createPage ${PdfJsStub.numPages} times`, () => {
        wrapper.instance().createPages(PdfJsStub.pdfDocument);
        expect(PdfJsStub.pdfjsCreatePage.callCount).to.equal(PdfJsStub.numPages);
      });

      it(`creates ${PdfJsStub.numPages} pages`, () => {
        wrapper.instance().createPages(PdfJsStub.pdfDocument);
        expect(wrapper.html()).to.include('pageContainer1');
        expect(wrapper.html()).to.include('pageContainer2');
        expect(wrapper.html()).to.include('pageContainer3');
      });

      context('when document.getElementById returns null', () => {
        let getElement;

        beforeEach(() => {
          getElement = sinon.stub(document, 'getElementById');
          getElement.returns(null);
        });

        it('create page is not called', () => {
          wrapper.instance().createPages(PdfJsStub.pdfDocument);
          expect(PdfJsStub.pdfjsCreatePage.callCount).to.equal(0);
        });

        afterEach(() => {
          getElement.restore();
        });
      });
    });

    context('.renderPage', () => {
      it('creates a new page', () => {
        expect(PdfJsStub.pdfjsRenderPage.callCount).to.equal(1);
        wrapper.instance().renderPage(1);
        expect(PdfJsStub.pdfjsRenderPage.callCount).to.equal(2);
      });

      it('only renders page once when called twice', (done) => {
        expect(PdfJsStub.pdfjsRenderPage.callCount).to.equal(1);
        wrapper.instance().renderPage(1).
          then(() => {
            wrapper.instance().renderPage(1);
            expect(PdfJsStub.pdfjsRenderPage.callCount).to.equal(2);
            done();
          }).
          catch(() => {
            // Should never get here since the render is mocked to succeed.
            assert.fail();
          });
      });

      context('mock renderPage to fail', (done) => {
        beforeEach(() => {
          PdfJsStub.pdfjsRenderPage.resetBehavior();
          PdfJsStub.pdfjsRenderPage.rejects();
        });

        it('tries to render page twice when called twice', () => {
          expect(PdfJsStub.pdfjsRenderPage.callCount).to.equal(1);
          wrapper.instance().renderPage(1).
            then(() => {
              // Should never get here since the render is mocked to fail.
              assert.fail();
            }).
            catch(() => {
              wrapper.instance().renderPage(1);
              expect(PdfJsStub.pdfjsRenderPage.callCount).to.equal(3);
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

    context('.onPageClick', () => {
      context('supplied with props.onPageClick', () => {
        let onPageClick;

        beforeEach(() => {
          onPageClick = sinon.spy();
          wrapper.setProps({
            onPageClick,
            scale: 2
          });
        });

        it('calls onPageClick prop', () => {
          let event = {
            offsetX: 10,
            offsetY: 10,
            target: {
              offsetLeft: 20,
              offsetTop: 30
            }
          };

          // The expected coordinate is
          // (( offsetX + offsetLeft ) / scale, (offsetY + offsetTop) / scale)
          // (( 10 + 20) / 2, (10 + 30) / 2)
          // (15, 20)
          let coordinate = {
            xPosition: 15,
            yPosition: 20
          };

          wrapper.instance().onPageClick(0)(event);
          expect(onPageClick.calledWith(0, coordinate)).to.be.true;
        });
      });
    });
  });

  /* eslint-enable max-statements */
});

/* eslint-enable no-unused-expressions */
