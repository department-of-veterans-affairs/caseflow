import React from 'react';
import { render } from '@testing-library/react';
import { axe } from 'jest-axe';

import AutoSave from 'app/components/AutoSave';

describe('AutoSave', () => {
  const defaultSave = jest.fn();

  const defaultProps = {
    save: defaultSave,
    isSaving: true,
    timeSaved: '11:00am',
  };

  const setup = (props) => {
    return render(<AutoSave {...defaultProps} {...props} />);
  };

  describe('rendering', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    it('passes a11y testing', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  describe('retry', () => {
    // Fake timers using Jest
    beforeEach(() => {
      jest.useFakeTimers();
    });
    // Running all pending timers and switching to real timers using Jest
    afterEach(() => {
      jest.runOnlyPendingTimers();
      jest.useRealTimers();
    });

    it('retries save at 30s intervals by default', () => {
      const save = jest.fn();

      setup({ save });

      expect(save).not.toBeCalled();
      // Default 30s interval in AutoSave
      jest.advanceTimersByTime(30000);
      expect(save).toHaveBeenCalledTimes(1);
    });

    it('retries save at set interval', () => {
      const save = jest.fn();

      setup({ intervalInMs: 45000, save });

      expect(save).not.toBeCalled();
      // Default 30s interval in AutoSave
      jest.advanceTimersByTime(30000);
      expect(save).not.toBeCalled();
      // Advance to the 45s interval sent to setup()
      jest.advanceTimersByTime(15000);
      expect(save).toHaveBeenCalledTimes(1);
    });

    it('retries save on window close', () => {
      const save = jest.fn();

      setup({ save });

      expect(save).not.toBeCalled();

      // Wrap in a timeout so nothing happens between calling
      // unload and checking
      let temporaryTimeout = setTimeout(() => {
        window.onbeforeunload();
        expect(save).toHaveBeenCalledTimes(1);
      });

      clearTimeout(temporaryTimeout);

    });
    it('retries save on unmount', () => {
      const save = jest.fn();

      const { unmount } = setup({ save });

      expect(save).not.toBeCalled();

      unmount();

      expect(save).toHaveBeenCalledTimes(1);
    });
  });
});

