import React from 'react';
import { expect } from 'chai';
import { mount, shallow } from 'enzyme';

import FileUpload from '../../../app/components/FileUpload';

describe('FileUpload', () => {
  let onChange = () => true;

  context('display text', () => {
    it('displays formatted value when set', () => {
      let wrapper = shallow(
        <FileUpload
          onChange={onChange}
          id="testing-file-upload"
          value={{ fileName: 'uploadedFile.pdf' }}
          preUploadText="Select a file for upload"
          postUploadText="Choose a different file"
        />
      );

      expect(wrapper.text()).to.include('uploadedFile.pdf');
    });

    it('displays postUploadText when value is set', () => {
      let wrapper = mount(
        <FileUpload
          onChange={onChange}
          id="testing-file-upload"
          value={{ fileName: 'uploadedFile.pdf' }}
          preUploadText="Select a file for upload"
          postUploadText="Choose a different file"
        />
      );

      expect(wrapper.text()).to.include('Choose a different file');
    });

    it('displays preUploadText when value is not set', () => {
      let wrapper = mount(
        <FileUpload
          onChange={onChange}
          id="testing-file-upload"
          value={null}
          preUploadText="Select a file for upload"
          postUploadText="Choose a different file"
        />
      );

      expect(wrapper.text()).to.include('Select a file for upload');
    });
  });
});
