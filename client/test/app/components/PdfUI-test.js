import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { WrappingComponent } from '../establishClaim/WrappingComponent';

import { PdfUI } from '../../../app/reader/PdfUI';

const DOCUMENT_PATH_BASE = '/reader/appeal/reader_id1';

jest.mock('../../../app/reader/Pdf', () => {
  return function MockPdf({ onPageChange }) {
    return <div data-testid="mock-pdf" onClick={() => onPageChange(2, 3)} />;
  };
});

jest.mock('../../../app/reader/PdfFile', () => {
  return function MockPdfFile({ onPageChange }) {
    return <div data-testid="mock-pdf-file" onClick={() => onPageChange(2, 3)} />;
  };
});

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


    describe('.onPageChange', () => {
      it('updates the state', () => {
        setup();
        const mockPdf = screen.getByTestId('mock-pdf');
        fireEvent.click(mockPdf);

        const pdfUiComponent = screen.getByTestId('pdf-ui');

        const currentPageTest = pdfUiComponent.getAttribute('cp-test');
        const fitToScreenZoomTest = pdfUiComponent.getAttribute('ftsz-test');

        expect(currentPageTest).toBe('2');
        expect(fitToScreenZoomTest).toBe('3');

        // // Simulate changing the page number input
        // fireEvent.change(pageNumberInput, { target: { value: '3' } });

        // // Simulate pressing the "Enter" key to change the page
        // fireEvent.keyPress(pageNumberInput, { key: 'Enter', code: 'Enter', charCode: 13 });

        // // Verify that the page number is updated correctly
        // expect(pageNumberInput.value).toBe('3');
      });
    });

    describe('changing the page number', () => {
      it('updates the value of the page number', () => {
        setup({
          numPages: 10,
        });
        const pageNumberInput = screen.getByRole('textbox', { name: 'Page' });
        expect(pageNumberInput.value).toBe('1');

        fireEvent.change(pageNumberInput, { target: { value: '3' } });
        fireEvent.keyPress(pageNumberInput, { key: 'Enter' });

        expect(pageNumberInput.value).toBe('3');
      });
    });

    describe('clicking', () => {
      describe('backToClaimsFolder', () => {
        it('calls the stopPlacingAnnotation props', () => {
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
