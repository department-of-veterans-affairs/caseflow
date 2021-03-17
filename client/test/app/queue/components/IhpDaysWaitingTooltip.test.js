import React from 'react';
import { render, screen } from '@testing-library/react';
import moment from 'moment';

import { axe } from 'jest-axe';

import IhpDaysWaitingTooltip from 'app/queue/components/IhpDaysWaitingTooltip';

const SERIALIZED_DATE_FORMAT = 'YYYY-MM-DDTkk:mm:ss.SSSZ';
const RENDERED_DATE_FORMAT = 'MM/DD/YY';
const DEFAULT_DAYS_AGO = {
  requestedAtDaysAgo: 20,
  receivedAtDaysAgo: 10
};

const WRAPPED_CONTENT = <span>10 days</span>;

describe('IhpDaysWaitingTooltip', () => {
  beforeEach(() => jest.clearAllMocks());

  const setup = (props = {}) => {
    return {
      ...render(
        <IhpDaysWaitingTooltip {...props}>
          {WRAPPED_CONTENT}
        </IhpDaysWaitingTooltip>
      ),
    };
  };

  const propifyDates = (daysAgo = DEFAULT_DAYS_AGO) => {
    const { requestedAtDaysAgo, receivedAtDaysAgo } = daysAgo;
    const requestedAt = isNaN(requestedAtDaysAgo) ? null : moment().subtract(requestedAtDaysAgo, 'd').
      format(SERIALIZED_DATE_FORMAT);
    const receivedAt = isNaN(receivedAtDaysAgo) ? null : moment().subtract(receivedAtDaysAgo, 'd').
      format(SERIALIZED_DATE_FORMAT);

    return {
      requestedAt,
      receivedAt
    };
  };

  const renderifyDates = (daysAgo = DEFAULT_DAYS_AGO) => {
    const { requestedAtDaysAgo, receivedAtDaysAgo } = daysAgo;
    const expectedRequestedAt = isNaN(requestedAtDaysAgo) ? '' : moment().subtract(requestedAtDaysAgo, 'd').
      format(RENDERED_DATE_FORMAT);
    const expectedReceivedAt = isNaN(receivedAtDaysAgo) ? '' : `${moment().subtract(receivedAtDaysAgo, 'd').
      format(RENDERED_DATE_FORMAT)} (${receivedAtDaysAgo} days)`;

    return {
      expectedRequestedAt,
      expectedReceivedAt
    };
  };

  it('renders correctly', async () => {
    const { container } = setup(propifyDates());

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup(propifyDates());

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  describe('no requested at date', () => {
    it('does not render the tooltip', async () => {
      setup();

      expect(screen.queryByText('IHP Requested:')).toBeFalsy();
    });
  });

  describe('non null requested at date', () => {
    it('renders the tooltip', async () => {
      setup(propifyDates());

      expect(screen.queryByText('IHP Requested:')).toBeTruthy();
    });

    it('displays the correct requested at date, received at date, and number of days waiting', () => {
      setup(propifyDates());

      const { expectedRequestedAt, expectedReceivedAt } = renderifyDates();

      expect(screen.getByTestId('ihp-requested').textContent).toEqual(`IHP Requested: ${expectedRequestedAt}`);
      expect(screen.getByTestId('ihp-received').textContent).toEqual(`IHP Received: ${expectedReceivedAt}`);
      expect(screen.getByTestId('ihp-days-waiting').textContent).toEqual('On hold for IHP: 10 days');
    });

    describe('ihp has not been received', () => {
      it('displays the number of days waiting since today but not the received at date', () => {
        const dates = {
          requestedAtDaysAgo: DEFAULT_DAYS_AGO.requestedAtDaysAgo
        };

        setup(propifyDates(dates));

        expect(screen.getByTestId('ihp-received').textContent).toEqual('IHP Received:  ');
        expect(screen.getByTestId('ihp-days-waiting').textContent).toEqual('On hold for IHP: 20 days');
      });
    });
  });
});
