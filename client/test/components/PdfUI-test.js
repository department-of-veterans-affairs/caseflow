import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import PdfUI from '../../app/components/PdfUI';
import sinon from 'sinon';

/* eslint-disable no-unused-expressions */
describe('PdfUI', () => {
  context('shallow create PdfUI', () => {
    let wrapper;
    let doc;

    beforeEach(() => {
      doc = {
        filename: 'My PDF',
        id: 'myPdf',
        type: 'Form 8',
        receivedAt: '1/2/2017'
      };

      wrapper = shallow(<PdfUI
        doc={doc}
        file="test.pdf"
        id="pdf"
        pdfWorker="noworker"
      />);
    });

    context('.render', () => {
      it('renders the outer div', () => {
        expect(wrapper.find('.cf-pdf-container')).to.have.length(1);
      });

      it('renders the title', () => {
        expect(wrapper.find('Button').find({ name: 'newTab' }).
          children().
          text()).to.eq(doc.filename);
      });

      it('renders the page number', () => {
        expect(wrapper.find('div').
          filterWhere((node) => node.
            text() === 'Page 1 of 1')).to.have.length(1);
      });

      it('renders the zoom buttons', () => {
        expect(wrapper.find({ name: 'zoomOut' })).to.have.length(1);
        expect(wrapper.find({ name: 'zoomIn' })).to.have.length(1);
      });

      context('when onNextPdf function is supplied', () => {
        it('renders the next PDF button', () => {
          expect(wrapper.find({ name: 'next' })).to.have.length(0);
          let onNextPdf = sinon.spy();

          wrapper.setProps({ onNextPdf });
          expect(wrapper.find({ name: 'next' })).to.have.length(1);
        });
      });

      context('when onPreviousPdf function is supplied', () => {
        it('renders the previous PDF button', () => {
          expect(wrapper.find({ name: 'previous' })).to.have.length(0);
          let onPreviousPdf = sinon.spy();

          wrapper.setProps({ onPreviousPdf });
          expect(wrapper.find({ name: 'previous' })).to.have.length(1);
        });
      });

      context('when onShowList function is supplied', () => {
        it('renders the back to document list button', () => {
          expect(wrapper.find({ name: 'backToDocuments' })).to.have.length(0);
          let onShowList = sinon.spy();

          wrapper.setProps({ onShowList });
          expect(wrapper.find({ name: 'backToDocuments' })).to.have.length(1);
        });
      });

      context('when onSetLabel function is supplied', () => {
        it('renders the Document Labels component', () => {
          expect(wrapper.find('DocumentLabels')).to.have.length(0);
          let onSetLabel = sinon.spy();

          wrapper.setProps({ onSetLabel });
          expect(wrapper.find('DocumentLabels')).to.have.length(1);
        });
      });
    });

    context('.onPageChange', () => {
      it('updates the state', () => {
        let currentPage = 2;
        let numPages = 4;

        wrapper.instance().onPageChange(currentPage, numPages);
        expect(wrapper.state('currentPage')).to.equal(currentPage);
        expect(wrapper.state('numPages')).to.equal(numPages);
      });

      it('updates the UI with the new page location', () => {
        let currentPage = 2;
        let numPages = 4;

        wrapper.instance().onPageChange(currentPage, numPages);
        expect(wrapper.find('div').
          filterWhere((node) => node.text() === `Page ${currentPage} of ${numPages}`)).
          to.have.length(1);
      });
    });

    context('.onColorLabelChange', () => {
      let onSetLabel;

      beforeEach(() => {
        onSetLabel = sinon.spy();
        wrapper.setProps({ onSetLabel });
      });

      it('calls the onSetLabel handler with a new label', () => {
        let newLabel = 'decision';

        wrapper.setProps({ label: '' });
        wrapper.instance().onColorLabelChange(newLabel)();
        expect(onSetLabel.calledWith(newLabel)).to.be.true;
      });

      it('calls the onSetLabel handler with the current label', () => {
        let label = 'decision';

        wrapper.setProps({ label });
        wrapper.instance().onColorLabelChange(label)();
        expect(onSetLabel.calledWith('')).to.be.true;
      });
    });

    context('.zoom', () => {
      it('sets the zoom state', () => {
        let delta = 0.5;
        let currentZoom = wrapper.state('scale');

        wrapper.instance().zoom(delta)();
        expect(wrapper.state('scale')).to.equal(currentZoom + delta);
      });
    });

    context('clicking', () => {
      // I'd like to use spies to make sure zoom is called
      // with the correct values instead of checking state
      // directly. But it proved to be too difficult to
      // spy on a closure generated within client code.
      context('zoomIn', () => {
        it('updates the scale by .3', () => {
          let delta = 0.3;
          let currentZoom = wrapper.state('scale');

          wrapper.find({ name: 'zoomIn' }).simulate('click');
          expect(wrapper.state('scale')).to.equal(currentZoom + delta);
        });
      });

      context('zoomOut', () => {
        it('updates the scale by -.3', () => {
          let delta = -0.3;
          let currentZoom = wrapper.state('scale');

          wrapper.find({ name: 'zoomOut' }).simulate('click');
          expect(wrapper.state('scale')).to.equal(currentZoom + delta);
        });
      });

      context('document name', () => {
        it('tries to open document in new tab', () => {
          let url = `/decision/review/show?id=${doc.id}&type=${doc.type}` +
            `&received_at=${doc.receivedAt}&filename=${doc.filename}`;
          let open = sinon.spy(window, 'open');

          wrapper.find('Button').find({ name: 'newTab' }).
            simulate('click');
          expect(open.withArgs(url, '_blank').calledOnce).to.be.true;
        });
      });

    });
  });
});
/* eslint-enable no-unused-expressions */
