import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { MemoryRouter } from 'react-router-dom';
import BuildScheduleUpload from '../../../../app/hearings/components/BuildScheduleUpload';
import { SPREADSHEET_TYPES } from '../../../../app/hearings/constants';

describe('BuildScheduleUpload', () => {
  it('does not show the date selector when file type is null', () => {
    const wrapper = mount(<MemoryRouter><BuildScheduleUpload /></MemoryRouter>);

    expect(wrapper.text()).to.include('Upload Files');
    expect(wrapper.text()).to.include('Please select the file you are uploading and choose a date range.');
    expect(wrapper.text()).to.not.include('Please input a date range');
  });

  it('shows the date selector when file type is \'Judge\'', () => {
    const wrapper = mount(<MemoryRouter><BuildScheduleUpload
      fileType={SPREADSHEET_TYPES.JudgeSchedulePeriod.value}
    /></MemoryRouter>);

    expect(wrapper.text()).to.include('What are you uploading?');
  });

  it('displays errors when set', () => {
    const wrapper = mount(<MemoryRouter><BuildScheduleUpload
      fileType={SPREADSHEET_TYPES.JudgeSchedulePeriod.value}
      uploadJudgeFormErrors={['Validation failed: The template was not followed.']}
    /></MemoryRouter>);

    expect(wrapper.text()).to.include('The template was not followed.');
  });
});
