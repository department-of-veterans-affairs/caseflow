import React from 'react';
import { screen, render, waitFor } from '@testing-library/react';
import CorrespondencePdfUI from '../../../../app/queue/correspondence/pdfPreview/CorrespondencePdfUI';
import { correspondenceDocumentsData } from '../../../data/correspondence';
import * as PDFJS from 'pdfjs-dist';
import ApiUtil from '../../../../app/util/ApiUtil';
import pdfjsWorker from 'pdfjs-dist/build/pdf.worker.entry';

PDFJS.GlobalWorkerOptions.workerSrc = pdfjsWorker;

jest.mock('pdfjs-dist');

const renderCorrespondencePdfUI = () => {
  render(<CorrespondencePdfUI selectedId={1} documents={correspondenceDocumentsData} />);
};

const createSpyGet = () => {
  return jest.spyOn(ApiUtil, 'get').mockImplementation(
    () =>
      new Promise((resolve) =>
        resolve({
          body: new ArrayBuffer(715640),
        })
      )
  );
};

describe('CorrespondencePdfUI', () => {

  beforeEach(() => {
    createSpyGet();
  });

  it('renders the Pdf UI', async () => {
    const mockGetViewport = jest.fn(() => ({
      height: 100,
      width: 100,
      scale: 1,
      rotation: 0
    }));

    const mockGetPage = jest.fn(() => ({
      promise: Promise.resolve({
        getViewport: mockGetViewport
      })
    }));

    const mockDocumentProxy = jest.fn(() => ({
      numPages: 3,
      getPage: mockGetPage
    }));

    PDFJS.getDocument.mockImplementation(() => ({
      promise: Promise.resolve(mockDocumentProxy)
    }));

    renderCorrespondencePdfUI();

    await waitFor(() => expect(PDFJS.getDocument).toHaveBeenCalledTimes(1));
    // if toolbar loads then the UI has succesfully loaded
    expect(screen.getByText('Zoom:')).toBeInTheDocument();
    expect(screen.getByText('Exam Request')).toBeInTheDocument();
  });
});
