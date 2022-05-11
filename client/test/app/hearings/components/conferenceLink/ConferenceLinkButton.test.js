import React from 'react';
import { amaHearing } from 'test/data/hearings';
import { anyUser, vsoUser } from 'test/data/user';
import { Button } from 'app/hearings/components/dailyDocket/DailyDocketRow';
import { axe } from 'jest-axe';
import { render, screen, fireEvent } from '@testing-library/react';

describe('Button', () => {
  const defaults = {
    classNames: 'usa-button-secondary',
    type: 'button'
  };

  const setup = (props) => {
    const { container } = render(<Button {...hearings} {...user} />);

    return { container };
  }
  ;
});
