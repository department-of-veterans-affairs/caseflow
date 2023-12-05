import React from 'react';
import { render, screen } from '@testing-library/react';
import { LastRetrievalAlert } from '../../../app/reader/LastRetrievalAlert';
import { alertMessage, warningMessage } from '../constants/LastRetrievalAlert'
import moment from 'moment';

describe('LastRetrievalAlert', () => {
  //const spy = jest.spyOn(moment, 'moment');
  // jest.mock('moment', () => {
  //   return () => jest.requireActual('moment')('05/11/23 12:40PM -0600');
  // });


  const defaultProps = {
    appeal: {
      veteran_full_name: "John Doe"
    },
    manifestVbmsFetchedAt: null
  };

  const renderComponent = (props = {}) => render(
    <LastRetrievalAlert {...defaultProps} {...props} />
  );

  it('does not render alert or warning message when eFolder document has been fetched and now is null', () => {
    const component = renderComponent({manifestVbmsFetchedAt: '05/10/23 10:34am EDT -0400'});

    expect(screen.queryByText(alertMessage)).toBeFalsy();
    expect(screen.queryByText(warningMessage)).toBeFalsy();
  });

  it('renders alert message when eFolder Document has not been fetched', () => {
    const component = renderComponent();

    expect(screen.getByText(alertMessage, { exact: false })).toBeTruthy();
    expect(screen.queryByText(warningMessage)).toBeFalsy();
  });

  it('renders warning message when now is returned', () => {
    Date.now = jest.fn().mockReturnValue(new Date('2023-05-11T12:40:00.000Z'));

    const component = renderComponent({manifestVbmsFetchedAt: '05/10/23 10:34am EDT -0400'});

    expect(screen.getByText(warningMessage, { exact: false })).toBeTruthy();
    expect(screen.queryByText(alertMessage)).toBeFalsy();
  });
});
