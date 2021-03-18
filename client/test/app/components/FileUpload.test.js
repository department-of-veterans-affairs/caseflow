import React from 'react';
import { axe } from 'jest-axe';
import { render, screen } from '@testing-library/react';

import FileUpload from '../../../app/components/FileUpload';

describe('FileUpload', () => {
  const onChange = () => true;

  describe('display text', () => {

    it('displays formatted value when set', async () => {
      const { container } = render(
        <FileUpload
          onChange={onChange}
          id="testing-file-upload"
          value={{ fileName: 'uploadedFile.pdf' }}
          preUploadText="Select a file for upload"
          postUploadText="Choose a different file"
        />
      );

      const file = screen.getByText('uploadedFile.pdf');

      // Renders correct text
      expect(file).toBeInTheDocument();

      const results = await axe(container);

      // Passes accessibility
      expect(results).toHaveNoViolations();

      // Matches snapshot
      expect(container).toMatchSnapshot();

    });

    it('displays postUploadText when value is set', async () => {
      const { container } = render(
        <FileUpload
          onChange={onChange}
          id="testing-file-upload"
          value={{ fileName: 'uploadedFile.pdf' }}
          preUploadText="Select a file for upload"
          postUploadText="Choose a different file"
        />
      );

      const text = screen.getByText('Choose a different file');

      // Renders correct text
      expect(text).toBeInTheDocument();

      const results = await axe(container);

      // Passes accessibility
      expect(results).toHaveNoViolations();

      // Matches snapshot
      expect(container).toMatchSnapshot();

    });

    it('displays preUploadText when value is not set', async () => {
      const { container } = render(<FileUpload
        onChange={onChange}
        id="testing-file-upload"
        value={null}
        preUploadText="Select a file for upload"
        postUploadText="Choose a different file"
      />);

      const text = screen.getByText('Select a file for upload');

      // Renders correct text
      expect(text).toBeInTheDocument();

      const results = await axe(container);

      // Passes accessibility
      expect(results).toHaveNoViolations();

      // Matches snapshot
      expect(container).toMatchSnapshot();

    });
  });
});
