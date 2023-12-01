import React, { useState as useStateMock } from 'react';
import { screen, render, fireEvent } from '@testing-library/react';
import CorrespondencePdfUI from '../../../../app/queue/correspondence/pdfPreview/CorrespondencePdfUI';
import { correspondenceDocumentsData } from '../../../data/correspondence';
import ApiUtil from '../../../../app/util/ApiUtil';
import PdfJsStub from '../../../helpers/PdfJsStub';

// jest.mock('pdfjs-dist', () => ({
//   // getDocument: jest.fn().mockResolvedValue({
//   //   promise: Promise.resolve({
//   //     numPages: 3,
//   //     getPage: jest.fn().mockResolvedValue({})
//   //   }),
//   // }),
//   GlobalWorkerOptions: jest.fn().mockResolvedValue(),
// }));

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

jest.mock('react', () => ({
  ...jest.requireActual('react'),
  useState: jest.fn()
}));

const setState = jest.fn();

const renderCorrespondencePdfUI = () => {
  render(<CorrespondencePdfUI selectedId={1} documents={correspondenceDocumentsData} />);
};

describe('CorrespondencePdfUI', () => {
  beforeEach(() => {
    PdfJsStub.beforeEach();
    createSpyGet();
  });
  it('loads the pdf ui first', () => {
    // mock loadingTask.promise
    // pdfjs.getDocument.mockResolvedValue({
    //   promise: Promise.resolve({
    //     numPages: 3,
    //     getPage: jest.fn().mockResolvedValue(3)
    //   })
    // });
    renderCorrespondencePdfUI();
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  // it('renders the Pdf UI', async () => {
  //   // mock loadingTask.promise
  //   pdfjs.getDocument.mockResolvedValue({
  //     promise: Promise.resolve({
  //       numPages: 3,
  //       getPage: jest.fn().mockResolvedValue(3)
  //     })
  //   });

  //   // After the promise resolves, we set the loadError to false
  //   // mockImplemnetationOnce runs whenever useState is ran.
  //   // In the component, useState is called twice before the loadError is set to False

  //   // Represents pdfDocProxy
  //   useStateMock.mockImplementationOnce(jest.fn());
  //   // Represents pdfPageProxies
  //   useStateMock.mockImplementationOnce(jest.fn());
  //   useStateMock.mockImplementationOnce(() => [false, setState]);

  //   const { container } = render(<CorrespondencePdfUI
  //     selectedId={1}
  //     documents={correspondenceDocumentsData}
  //   />);

  //   // will fail atm, need to setup mock document data and mock resolved values above
  //   expect(container.querySelector('.cf-pdf-preview-container')).toBeInTheDocument();
  // });
});
