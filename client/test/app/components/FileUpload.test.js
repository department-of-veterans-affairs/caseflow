import React from 'react';
import { render, screen, cleanup } from '@testing-library/react';

import FileUpload from '../../../app/components/FileUpload';

describe('FileUpload', () => {
  let onChange = () => true;

  describe('display text', () => {

    afterEach(() => {
      cleanup();
    });
    it('displays formatted value when set', () => {
      render(
        <FileUpload
          onChange={onChange}
          id="testing-file-upload"
          value={{ fileName: 'uploadedFile.pdf' }}
          preUploadText="Select a file for upload"
          postUploadText="Choose a different file"
        />
      );

      const file = screen.getByText('uploadedFile.pdf');

      expect(file).toBeInTheDocument();
    });

    it('displays postUploadText when value is set', () => {
      render(
        <FileUpload
          onChange={onChange}
          id="testing-file-upload"
          value={{ fileName: 'uploadedFile.pdf' }}
          preUploadText="Select a file for upload"
          postUploadText="Choose a different file"
        />
      );

      const text = screen.getByText('Choose a different file');

      expect(text).toBeInTheDocument();
    });

    it('displays preUploadText when value is not set', () => {
      render(
        <FileUpload
          onChange={onChange}
          id="testing-file-upload"
          value={null}
          preUploadText="Select a file for upload"
          postUploadText="Choose a different file"
        />
      );

      const text = screen.getByText('Select a file for upload');

      expect(text).toBeInTheDocument();
    });
  });
});
