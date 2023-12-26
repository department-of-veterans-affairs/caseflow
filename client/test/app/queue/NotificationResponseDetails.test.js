import React from 'react';
import { render } from '@testing-library/react';
import { axe } from 'jest-axe';
import NotificationResponseDetails from '../../../app/queue/components/NotificationResponseDetails';

describe('NotificationResponseDetails', () => {
  const appellantAcknowledgement = 'Yes';
  const responseDate = '12/26/2023';
  const responseTime = '12:00';
  const appellantAcknowledgementDenial = 'No';

  const setup = (response, date, time) => {
    return render(<NotificationResponseDetails response={response} date={date} time={time} />);
  };

  it('renders "Yes" in Appellant Acknowledgement', () => {
    const { container } = setup(appellantAcknowledgement, responseDate, responseTime);
    const cell = container.querySelectorAll('td')[6];

    expect(cell.textContent).toBe('Yes');
  });

  it('renders "12/26/2023" in Response Date', () => {
    const { container } = setup(appellantAcknowledgement, responseDate, responseTime);
    const cell = container.querySelectorAll('td')[7];

    expect(cell.textContent).toBe('12/26/2023');
  });

  it('renders "12:00" in Response Time', () => {
    const { container } = setup(appellantAcknowledgement, responseDate, responseTime);
    const cell = container.querySelectorAll('td')[8];

    expect(cell.textContent).toBe('12:00');
  });

  it('renders "No" in Appellant Acknowledgement', () => {
    const { container } = setup(appellantAcknowledgementDenial, responseDate, responseTime);
    const cell = container.querySelectorAll('td')[6];

    expect(cell.textContent).toBe('No');
  });

  it('matches snapshot', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('Virtual passes ally testing', async () => {
    const { container } = setup();
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
