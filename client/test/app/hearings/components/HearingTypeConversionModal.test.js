import React from 'react';
import { render, screen } from '@testing-library/react';
import { logRoles } from '@testing-library/react';
import { mount } from 'enzyme';

import { appealData } from '../../../data/appeals';
import { queueWrapper } from '../../../data/stores/queueStore';
import HearingTypeConversionModal from '../../../../app/hearings/components/HearingTypeConversionModal';
import Modal from '../../../../app/components/Modal';
import COPY from 'COPY';
import { log } from 'console';
import exp from 'constants';

const Wrapper = ({ children }) => {
  return queueWrapper({ children });
};

describe('HearingTypeConversion', () => {
  test('Displays convert to Video text when converting from Video', () => {
    const {container} = render(
      <HearingTypeConversionModal
        appeal={appealData}
        hearingType="Video"
      />,
      {
        wrapper: Wrapper,
      }
    );

    const heading = screen.getByRole('heading', { name: /Convert Hearing To Video/i });
    expect(heading).toBeInTheDocument();

    expect(screen.queryByText(/Central Office/i)).not.toBeInTheDocument();
    expect(
      screen.queryByText((content) => content.includes(COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT))
    ).toBeInTheDocument();
    console.log(COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT)
    expect(container).toMatchSnapshot();
  });

  test.only('Displays convert to Central text when converting from Central', () => {
    const { container } = render(
      <HearingTypeConversionModal
        appeal={appealData}
        hearingType="Central"
      />,
      {
        wrapper: Wrapper,
      }
    );

    const heading = screen.getByRole('heading', { name: /Convert Hearing To Central/i });
    expect(heading).toBeInTheDocument();
    logRoles(container);

    expect(screen.queryByText(/Central Office/i)).toBeInTheDocument();
    expect(screen.queryByText((content) => content.includes(COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT))
    ).not.toBeInTheDocument();
    expect(container).toMatchSnapshot();
  });
});
