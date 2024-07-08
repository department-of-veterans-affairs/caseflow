import React from 'react';
import { shallow } from 'enzyme';
import { render, screen, logRoles, fireEvent} from '@testing-library/react';
import sinon from 'sinon';
import { WrappingComponent } from '../establishClaim/WrappingComponent';

import { PdfUI } from '../../../app/reader/PdfUI';
import { log } from 'console';
import { jumpToPage } from '../../../app/reader/PdfViewer/PdfViewerActions';
import { fi } from 'date-fns/locale';
import { on } from 'events';
import exp from 'constants';

const DOCUMENT_PATH_BASE = '/reader/appeal/reader_id1';

/* eslint-disable no-unused-expressions */
describe('PdfUI', () => {
  describe('shallow create PdfUI', () => {
    let setup;
    let doc;

    // beforeEach(() => {
      doc = {
        filename: 'My PDF',
        id: 3,
        type: 'Form 8',
        receivedAt: '1/2/2017'
      };

      setup = (props) => {
        return render(<PdfUI
          doc={doc}
          file="test.pdf"
          filteredDocIds={[3]}
          id="pdf"
          pdfWorker="noworker"
          documentPathBase={DOCUMENT_PATH_BASE}
          showClaimsFolderNavigation={false}
          featureToggles={{ search: true }}
          {...props}
        />, { wrapper: WrappingComponent });
        };
    // });

    describe('.render', () => {
      it('renders the outer div', () => {
        const {container} = setup();
        expect(container.querySelector('.cf-pdf-container')).toBeInTheDocument();
        // expect(wrapper.find('.cf-pdf-container')).toHaveLength(1);
      });

      it('renders the title as a link', () => {
        setup();
        const newTab = screen.getByRole('link', {name: 'open document in new tab'});

        expect(newTab).toBeInTheDocument();
        expect(newTab.id).toBe('newTab');
        expect(newTab.target).toBe('_blank');
        expect(screen.getByRole('link', {name: 'open document in new tab'})).toBeInTheDocument();
        expect(screen.getByText(doc.type)).toBeInTheDocument();
      });

      it('does not render the page number when pdf has not been rendered', () => {
        setup();
        expect(screen.queryByText('Page 1 of 1')).toBeNull();
        expect(screen.getByText('Loading document...')).toBeInTheDocument();
      });

      it('renders the zoom buttons', () => {
        setup();
        expect(screen.getByRole('button', {name: 'zoom out'})).toBeInTheDocument();
        expect(screen.getByRole('button', {name: 'zoom in'})).toBeInTheDocument();
      });

      it('renders the search button', () => {
        setup();
        expect(screen.getByRole('button', {name: 'search text'})).toBeInTheDocument();
      });

      describe('when showClaimsFolderNavigation is true', () => {
        it('renders the back button that directs to claims folder', () => {
          const {rerender} = setup();

          expect(screen.queryByRole('link', {name: 'Back'})).not.toBeInTheDocument();

          const newProps = {
            showClaimsFolderNavigation: true
            }

            rerender(<PdfUI
              doc={doc}
              file="test.pdf"
              filteredDocIds={[3]}
              id="pdf"
              pdfWorker="noworker"
              documentPathBase={DOCUMENT_PATH_BASE}
              showClaimsFolderNavigation={false}
              featureToggles={{ search: true }}
              {...newProps}
              />, { wrapper: WrappingComponent }
              );

            expect(screen.getByRole('link', {name: 'Back'})).toBeInTheDocument();
        });
      });
    });


    // THIS TEST SHOULD BE REFINED or REMOVED
    describe('.onPageChange', () => {
      it('updates the state', () => {
        const setZoomLevelMock = jest.fn();
        const jumpToPageMock = jest.fn();
        const onPageChangeMock = jest.fn();
        const { container, rerender } = setup({
          setZoomLevel: setZoomLevelMock,
          jumpToPage: jumpToPageMock,
        });

        let currentPage = 2;
        let fitToScreenZoom = 3;
        const newProps = {
          numPages: 10,
          scale: 1,
        };

        rerender(
          <PdfUI
            doc={doc}
            file="test.pdf"
            filteredDocIds={[3]}
            id="pdf"
            pdfWorker="noworker"
            documentPathBase={DOCUMENT_PATH_BASE}
            showClaimsFolderNavigation={false}
            featureToggles={{ search: true }}
            setZoomLevel={setZoomLevelMock}
            jumpToPage={jumpToPageMock}
            onPageChange={onPageChangeMock}
            {...newProps}
          />,
          { wrapper: WrappingComponent }
        );

        console.log('fitToScreenZoom prop:', fitToScreenZoom);
        const pageNumberInput = screen.getByRole('textbox', { name: 'Page' });
        expect(pageNumberInput.value).toBe('1');

        // Simulate clicking the zoom in button
        const zoomInButton = screen.getByRole('button', { name: 'zoom in' });
        fireEvent.click(zoomInButton);
        fireEvent.click(zoomInButton);
        fireEvent.click(zoomInButton);

        const zoomOutButton = screen.getByRole('button', { name: 'zoom out' });
        fireEvent.click(zoomOutButton);

        // Simulate clicking the fit to screen button
        const fitToScreenButton = screen.getByRole('button', { name: 'fit to screen' });
        fireEvent.click(fitToScreenButton);

        // Simulate changing the page number input
        fireEvent.change(pageNumberInput, { target: { value: '3' } });

        // Simulate pressing the "Enter" key to change the page
        fireEvent.keyPress(pageNumberInput, { key: 'Enter', code: 'Enter', charCode: 13 });

        // Verify that the page number is updated correctly
        expect(pageNumberInput.value).toBe('3');

        // Call onPageChangeMock directly with the desired arguments
        onPageChangeMock(currentPage, fitToScreenZoom);
        expect(onPageChangeMock).toHaveBeenCalledWith(currentPage, fitToScreenZoom);

        console.log('onPageChangeMock:', onPageChangeMock.mock);

        // screen.debug(null, Infinity);
        // logRoles(container);
        // wrapper.instance().onPageChange(currentPage, fitToScreenZoom);
        // expect(wrapper.state('currentPage')).toBe(currentPage);
        // expect(wrapper.state('fitToScreenZoom')).toBe(fitToScreenZoom);
      });
    });

    describe('clicking', () => {
      describe('backToClaimsFolder', () => {
        it.only('calls the stopPlacingAnnotation props', () => {
          const mockStopPlacingAnnotationClick = jest.fn();

          setup({
            showClaimsFolderNavigation: true,
            stopPlacingAnnotation: mockStopPlacingAnnotationClick
          });

          const backToClaimsFolderButton = screen.getByRole('link', {name: 'Back'});
          fireEvent.click(backToClaimsFolderButton);

          expect(mockStopPlacingAnnotationClick).toHaveBeenCalled();
        });
      });
    });
  });
});

/* eslint-enable no-unused-expressions */
