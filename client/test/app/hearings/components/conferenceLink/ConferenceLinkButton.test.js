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
    const { container } = render(<Button {...defaults} {...props} />);

    return { container };
  };

  it('renders properly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes A11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('calls onClick when clicked', async () => {
    const onClick = jest.fn();

    setup({ onClick });

    const buttonElement = screen.getByRole('button');

    expect(buttonElement).toBeInTheDocument();
    expect(onClick).toHaveBeenCalledTimes(0);

    await userEvent.click(buttonElement);
    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it('respects loading prop', () => {
    const loading = true;

    setup({ loading });

    const loadingText = 'Loading...';
    const loadingTextElement = screen.getByText(loadingText);

    expect(loadingTextElement).toBeInTheDocument();
  });
  it('respects disabled prop and removes other classes when disabled', () => {
    const disabled = true;

    setup({ disabled });

    const buttonElement = screen.getByRole('button');

    expect(buttonElement.classList.contains('usa-button-secondary')).toBeTruthy();
    expect(buttonElement.classList.contains('usa-button-primary')).toBeFalsy();
  });
});

/**
 * 
 ** Do a try catch error, that if the container components does not render properly to display correct hyperlink label,it throw error.
 test('the data is conference link', done => {
  function callback(error, data) {
    if (error) {
      done(error);
      return;
    }
    try {
      expect(data).toBe('conference link');
      done();
    } catch (error) {
      done(error);
    }
  }

  fetchData(callback);
});
 */
/** 
describe('StaticVirtualHearing', () => {
  const defaultProps = {
    user: anyUser,
    hearing: amaHearing
  };

  it('renders correctly', () => {
    const { container } = render(<StaticVirtualHearing {...defaultProps} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<StaticVirtualHearing {...defaultProps} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('displays correct label for host user', () => {
    const component = render(
      <StaticVirtualHearing {...defaultProps} user={{ userId: amaHearing.judgeId }} />
    );

    expect(component).toMatchSnapshot();
    expect(screen.getByText(COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL_FULL)).toBeInTheDocument();
  });
});
**/
