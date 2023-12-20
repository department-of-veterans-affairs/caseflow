import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { axe } from 'jest-axe';

import { amaHearing } from 'test/data/hearings';
import { anyUser, vsoUser } from 'test/data/user';

import COPY from '../../../../../COPY';
import { StaticVirtualHearing } from 'app/hearings/components/dailyDocket/DailyDocketRowInputs';

describe('StaticVirtualHearing', () => {
  const defaultProps = {
    user: anyUser,
    hearing: amaHearing
  };


  it('renders correctly', () => {
    const { container } = render(<StaticVirtualHearing {...defaultProps} />);

    expect(container).toMatchSnapshot();
  })

  it('passes a11y testing', async () => {
    const { container } = render(<StaticVirtualHearing {...defaultProps} />);

    const results = await axe(container);
    expect(results).toHaveNoViolations();
  })

  it('displays correct label for host user', () => {
    const component = render(
      <StaticVirtualHearing {...defaultProps} user={{ userId: amaHearing.judgeId }}/>
    );

    expect(component).toMatchSnapshot();
    expect(screen.getByText(COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL_FULL)).toBeInTheDocument()
  })

  it('displays correct label for guest user', () => {
    const component = render(
      <StaticVirtualHearing {...defaultProps} user={vsoUser}/>
    );

    expect(component).toMatchSnapshot();
    expect(screen.getByText(COPY.REPRESENTATIVE_VIRTUAL_HEARING_LINK_LABEL)).toBeInTheDocument()
  })
})
