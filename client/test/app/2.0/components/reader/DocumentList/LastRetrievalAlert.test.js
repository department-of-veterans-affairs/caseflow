import React from 'react';
import { render, screen } from '@testing-library/react';
import { LastRetrievalAlert } from '../../../../../../app/2.0/components/reader/DocumentList/LastRetrievalAlert';
import * as format from '../../../../../../app/2.0/utils/reader/format';
import { alertMessage, warningMessage } from './constants/LastRetrievalAlert'

describe('LastRetrievalAlert', () => {
  const spy = jest.spyOn(format, 'formatAlertTime')

  const defaultProps = {
    appeal: {
      veteran_full_name: "John Doe"
    },
    manifestVbmsFetchedAt: null
  };

  const renderComponent = (props = {}) => render(
    <LastRetrievalAlert {...defaultProps} {...props} />
  );

  it('does not render alert or warning message when manifest VBMS has been fetched and now is null', () => {
    const component = renderComponent({manifestVbmsFetchedAt: '05/10/23 10:34am EDT -0400'});

    expect(screen.queryByText(alertMessage)).toBeFalsy();
    expect(screen.queryByText(warningMessage)).toBeFalsy();
  });

  it('renders alert message when manifest VBMS has not been fetched', () => {
    const component = renderComponent();

    expect(screen.getByText(alertMessage)).toBeTruthy();
    expect(screen.queryByText(warningMessage)).toBeFalsy();
  });

  it('renders warning message when now is returned', () => {
    spy.mockReturnValueOnce({now: '05/11/23 12:40PM -0600', vbmsDiff: 15});
    const component = renderComponent({manifestVbmsFetchedAt: '05/10/23 10:34am EDT -0400'});

    expect(screen.getByText(warningMessage)).toBeTruthy();
    expect(screen.queryByText(alertMessage)).toBeFalsy();
  });
});
