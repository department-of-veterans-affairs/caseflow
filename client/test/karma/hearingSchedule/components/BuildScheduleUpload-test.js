import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import BuildScheduleUpload from '../../../../app/hearingSchedule/components/BuildScheduleUpload';

describe('BuildScheduleUpload', () => {
  it('does not show the date selector when file type is null', () => {
    const wrapper = mount(<BuildScheduleUpload />);

    expect(wrapper.text()).to.include('Upload Files');
    expect(wrapper.text()).to.include('Please select the file you are uploading and choose a date range.');
    expect(wrapper.text()).to.not.include('Please input a date range');
  });
});
