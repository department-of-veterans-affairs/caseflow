import React from 'react';
import { mount } from 'enzyme';
import { MemoryRouter } from 'react-router-dom';
import BuildScheduleUpload from '../../../../../../client/app/hearings/components/BuildScheduleUpload';
import { SPREADSHEET_TYPES } from '../../../../../../client/app/hearings/constants';

describe('BuildScheduleUpload', () => {
  it('does not show the date selector when file type is null', () => {
    const wrapper = mount(<MemoryRouter><BuildScheduleUpload /></MemoryRouter>);

    expect(wrapper.text().includes('Upload Files')).toBe(true);
    expect(wrapper.text().includes('Please select the file you are uploading and choose a date range.')).toBe(true);
    expect(wrapper.text().includes('Please input a date range')).toBe(false);
  });

  it('shows the date selector when file type is \'Judge\'', () => {
    const wrapper = mount(<MemoryRouter><BuildScheduleUpload
      fileType={SPREADSHEET_TYPES.JudgeSchedulePeriod.value}
    /></MemoryRouter>);

    expect(wrapper.text().includes('What are you uploading?')).toBe(true);
  });

  it('displays errors when set', () => {
    const wrapper = mount(<MemoryRouter><BuildScheduleUpload
      fileType={SPREADSHEET_TYPES.JudgeSchedulePeriod.value}
      uploadJudgeFormErrors={['Validation failed: The template was not followed.']}
    /></MemoryRouter>);

    expect(wrapper.text().includes('The template was not followed.')).toBe(true);
  });
});
