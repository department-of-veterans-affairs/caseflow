import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import ProgressBar from '../../../../app/readerprototype/components/ProgressBar';
import PdfDocument from '../../../../app/readerprototype/components/PdfDocument';
import { Provider } from 'react-redux';
import { def, get } from 'bdd-lazy-var/getter';
import fs from 'fs';
import { getDocument } from 'pdfjs-dist/es5/build/pdf';

jest.mock('pdfjs-dist');

const dummyStore = {
  getState: () => ({}),
  dispatch: jest.fn(),
  subscribe: jest.fn()
};

describe('tests for ProgressBar component', () => {
  const handleCancelRequest = jest.fn();
  const progressProps = {
    progressPercentage: 50,
    loadedBytes: 100,
    totalBytes: 200,
    handleCancelRequest,
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('renders correctly', () => {
    const { container } = render(<ProgressBar {...progressProps} />);
    expect(container).toMatchSnapshot();
  });

  test('displays percentage', () => {
    const { getByText } = render(<ProgressBar {...progressProps} />);
    expect(getByText('50% downloaded')).toBeInTheDocument();
  });

  test('displays loaded and total bytes', () => {
    const { getByText } = render(<ProgressBar {...progressProps} />);
    expect(getByText('100 MB of 200 MB')).toBeInTheDocument();
  });

  test('calls handleCancelRequest on click of cancel button', () => {
    const { getByText } = render(<ProgressBar {...progressProps} />);
    const cancelButton = getByText('Cancel');
    fireEvent.click(cancelButton);
    expect(handleCancelRequest).toHaveBeenCalledTimes(1);
  });
});

describe('tests for ProgressBar integration with PdfDocument', () => {
  const doc = {
    content_url: 'test-url',
    filename: 'test-file',
    id: 1,
    type: 'test-type',
    file_size: 100,
  };

  const pdfProps = {
    currentPage: 1,
    doc,
    isDocumentLoadError: false,
    rotateDeg: '0',
    setIsDocumentLoadError: jest.fn(),
    setNumPages: jest.fn(),
    zoomLevel: 1,
    onrequestCancel: jest.fn(),
  };

  def(
    'render',
    () => async () => {
      const pdfData = async () => {
        const raw = fs.readFileSync('test/fixtures/pdfs/Informal_Form9.pdf');
        const arrayBuffer = raw.buffer;
        const pdf = await getDocument({ data: arrayBuffer }).promise;
        return pdf;
      };

      return render(
        <Provider store={dummyStore}>
          <PdfDocument {...pdfProps} pdf={await pdfData()} />
        </Provider>
      );
    }
  );

  test('renders', async () => {
    const { container } = await get.render();
    expect(container).toMatchSnapshot();
  });

  test('hides progress bar after document loads', async () => {
    const { queryByText } = await get.render();
    await waitFor(() => expect(queryByText('Downloading document...')).not.toBeInTheDocument());
  });

  test('renders document', async () => {
    const { container } = await get.render();
    await waitFor(() => expect(container).toMatchSnapshot());
  });
});
