import React from 'react';
import { render, screen, waitFor, act } from '@testing-library/react';
import { axe } from 'jest-axe';

import COPY from '../../../COPY';
import LoadingDataDisplay from 'app/components/LoadingDataDisplay';

describe('LoadingDataDisplay', () => {
  const TIMEOUT_MS = 4000;
  const createInfiniteLoadPromise = () => new Promise(() => {});
  const createFailingPromise = (status) =>
    () => new Promise((resolve, reject) => setTimeout(() => reject(status), TIMEOUT_MS/1000))

  const loadingScreenMessage = 'Loading screen message';
  const successMessage = 'Success message'
  const defaultProps = {
    createLoadPromise: createInfiniteLoadPromise,
    loadingComponentProps: {
      message: loadingScreenMessage
    }
  };

  const renderComponent = (props = {}) => render(
    <LoadingDataDisplay {...defaultProps} {...props}>
      <p>{successMessage}</p>
    </LoadingDataDisplay>
  );

  it('displays loading state initally', () => {
    const { container } = renderComponent()

    expect(container).toMatchSnapshot();

    expect(screen.getByText(loadingScreenMessage)).toBeInTheDocument();
  });

  it('passes a11y testing', async () => {
    const { container } = renderComponent()

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });


  it('displays success msg', async () => {
    const createLoadPromise = () => new Promise((resolve, reject) => setTimeout(() => resolve(), TIMEOUT_MS/1000))
    renderComponent({ createLoadPromise })

    expect(await screen.findByText(successMessage)).toBeInTheDocument()
  })

  it('displays access denied msg in fail component', async () => {
    const status = { status: 403 }
    const { container } = renderComponent({ createLoadPromise: createFailingPromise(status)})

    expect(await screen.findByText(COPY.ACCESS_DENIED_TITLE)).toBeInTheDocument()
  })

  it('displays not found msg in fail component', async () => {
    const status = { status: 404 }
    renderComponent({ createLoadPromise: createFailingPromise(status)})

    expect(await screen.findByText(COPY.INFORMATION_CANNOT_BE_FOUND)).toBeInTheDocument()
  })

  it('displays custom error msg in fail component', async () => {
    const status = { status: 500 }
    renderComponent({
      createLoadPromise: createFailingPromise(status),
      failStatusMessageChildren: <p>Fail message</p>
    })

    expect(await screen.findByText('Fail message')).toBeInTheDocument()
  })

  it('displays slow loading state', async () => {
    jest.useFakeTimers('modern');
    const slowLoadThresholdMs = TIMEOUT_MS / 10
    renderComponent({ slowLoadThresholdMs })

    await waitFor(() => {
      expect(screen.getByText(COPY.SLOW_LOADING_MESSAGE)).toBeInTheDocument();
    }, {timeout: slowLoadThresholdMs})
  })

  it('displays timeout state', async () => {
    jest.useFakeTimers('modern');
    const timeoutMs = TIMEOUT_MS / 10
    renderComponent({ timeoutMs })

    await waitFor(() => {
      expect(screen.getByText(COPY.DEFAULT_UNKNOWN_ERROR_MESSAGE)).toBeInTheDocument();
    }, {timeout: timeoutMs})
  })
});
