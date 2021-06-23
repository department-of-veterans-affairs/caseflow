import React from 'react';

import { mount } from 'enzyme';

import { appealData } from '../../../data/appeals';
import { queueWrapper } from '../../../data/stores/queueStore';
import HearingTypeConversionModal from '../../../../app/hearings/components/HearingTypeConversionModal';
import Modal from '../../../../app/components/Modal';
import COPY from 'COPY';

describe('HearingTypeConversion', () => {
  test('Displays convert to Video text when converting from Video', () => {
    const hearingTypeConversion = mount(
      <HearingTypeConversionModal
        appeal={appealData}
        hearingType="Video"
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(hearingTypeConversion.exists(Modal)).toBeTruthy();
    expect(hearingTypeConversion.find(Modal).text()).not.toContain('Central Office');
    expect(hearingTypeConversion.find(Modal).text()).toContain(COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT);
    expect(hearingTypeConversion).toMatchSnapshot();
  });

  test('Displays convert to Central text when converting from Central', () => {
    const hearingTypeConversion = mount(
      <HearingTypeConversionModal
        appeal={appealData}
        hearingType="Central"
      />,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(hearingTypeConversion.exists(Modal)).toBeTruthy();
    expect(hearingTypeConversion.find(Modal).text()).toContain('Central Office');
    expect(hearingTypeConversion.find(Modal).text()).
      not.toContain(COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT);
    expect(hearingTypeConversion).toMatchSnapshot();
  });
});
