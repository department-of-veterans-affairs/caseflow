import React from 'react';
import {
  render,
  fireEvent,
  screen,
  wait,
  waitFor,
} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderHook } from '@testing-library/react-hooks';

import { axe } from 'jest-axe';

import { Tabs } from 'app/components/tabs/Tabs';
import { Tab } from 'app/components/tabs/Tab';

import { tabList } from '../../../data';
import { useUniquePrefix } from '../../../../app/components/tabs/TabContext';
const tabData = tabList.map(({ disabled, label, page }) => ({
  disabled,
  title: label,
  contents: page,
}));

const checkA11yActiveTab = ({ container, activeIdx }) => {
  const headers = container.getAllByRole('tab');
  const panels = container.getAllByRole('tabpanel', { hidden: true });

  headers.forEach((item, idx) => {
    // Check tabindex on tab buttons
    expect(item.getAttribute('tabindex')).toBe(idx === activeIdx ? '0' : '-1');

    // Check aria-selected on tab buttons
    expect(item.getAttribute('aria-selected')).toBe(
      idx === activeIdx ? 'true' : 'false'
    );

    // Check for "active" styling
    expect(item.classList.contains('cf-active')).toBe(idx === activeIdx);
  });

  panels.forEach((item, idx) => {
    // Check aria-hidden on tab panels
    expect(item.getAttribute('aria-hidden')).toBe(
      idx === activeIdx ? 'false' : 'true'
    );
  });
};

// Ensure our id prefix doesn't screw up snapshots
const idPrefix = 'abc123';

describe('Tabs', () => {
  it('renders correctly', async () => {
    const { container } = await render(
      <Tabs idPrefix={idPrefix}>
        {tabData.map(({ disabled, title, contents }, idx) => (
          <Tab key={idx + 1} title={title} value={idx + 1} disabled={disabled}>
            <p>{contents}</p>
          </Tab>
        ))}
      </Tabs>
    );

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = await render(
      <Tabs idPrefix={idPrefix}>
        {tabData.map(({ disabled, title, contents }, idx) => (
          <Tab key={idx + 1} title={title} value={idx + 1} disabled={disabled}>
            <p>{contents}</p>
          </Tab>
        ))}
      </Tabs>
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('shows only active tab', async () => {
    await render(
      <Tabs idPrefix={idPrefix}>
        {tabData.map(({ disabled, title, contents }, idx) => (
          <Tab key={idx + 1} title={title} value={idx + 1} disabled={disabled}>
            <p>{contents}</p>
          </Tab>
        ))}
      </Tabs>
    );

    expect(screen.getAllByRole('tablist').length).toBe(1);
    expect(screen.getAllByRole('tabpanel', { hidden: true }).length).toBe(
      tabData.length
    );
    expect(screen.getAllByRole('tabpanel', { hidden: false }).length).toBe(1);

    expect(screen.getByText(tabData[0].contents)).toBeTruthy();
  });

  /*   eslint-disable jest/expect-expect */
  it('should switch tab styling, content, and accessibility attributes', async () => {
    await render(
      <Tabs idPrefix={idPrefix}>
        {tabData.map(({ disabled, title, contents }, idx) => (
          <Tab key={idx + 1} title={title} value={idx + 1} disabled={disabled}>
            <p>{contents}</p>
          </Tab>
        ))}
      </Tabs>
    );

    checkA11yActiveTab({ container: screen, activeIdx: 0 });

    userEvent.click(screen.getByText(tabData[1].title));

    checkA11yActiveTab({ container: screen, activeIdx: 1 });
  });
  /*   eslint-enable jest/expect-expect */

  it('should allow switching of tabs via keyboard', async () => {
    await render(
      <Tabs idPrefix={idPrefix}>
        {tabData.map(({ disabled, title, contents }, idx) => (
          <Tab key={idx + 1} title={title} value={idx + 1} disabled={disabled}>
            <p>{contents}</p>
          </Tab>
        ))}
      </Tabs>
    );

    const headers = screen.getAllByRole('tab');

    // Start on the second tab
    userEvent.click(headers[1]);

    expect(headers[1]).toBe(document.activeElement);

    // Go left!
    fireEvent.keyDown(headers[1], { key: 'ArrowLeft' });

    await wait(() => {
      expect(headers[0]).toBe(document.activeElement);
    });

    // Can't go further left
    fireEvent.keyDown(headers[0], { key: 'ArrowLeft' });

    await wait(() => {
      expect(headers[0]).toBe(document.activeElement);
    });

    // Go back right!
    fireEvent.keyDown(headers[0], { key: 'ArrowRight' });

    await wait(() => {
      expect(headers[1]).toBe(document.activeElement);
    });

    // Can't go further right
    fireEvent.keyDown(headers[1], { key: 'ArrowRight' });

    await wait(() => {
      expect(headers[1]).toBe(document.activeElement);
    });
  });

  it('should disallow switching of tabs via keyboard if keyNav is false', async () => {
    await render(
      <Tabs idPrefix={idPrefix} keyNav={false}>
        {tabData.map(({ disabled, title, contents }, idx) => (
          <Tab key={idx + 1} title={title} value={idx + 1} disabled={disabled}>
            <p>{contents}</p>
          </Tab>
        ))}
      </Tabs>
    );

    const headers = screen.getAllByRole('tab');

    // Start on the second tab
    userEvent.click(headers[1]);

    expect(headers[1]).toBe(document.activeElement);

    // Try going left
    fireEvent.keyDown(headers[1], { key: 'ArrowLeft' });

    // Focus should not have moved
    await wait(() => {
      expect(headers[1]).toBe(document.activeElement);
    });

    // Try right
    fireEvent.keyDown(headers[0], { key: 'ArrowRight' });

    // Focus should not have moved
    await wait(() => {
      expect(headers[1]).toBe(document.activeElement);
    });
  });

  it('should tab into the tabpanel', async () => {
    await render(
      <Tabs idPrefix={idPrefix}>
        <Tab title="Tab 1" value="1">
          <p>Tab contents 1</p>
          <ul>
            <li>
              <a href="#">Link 1</a>
            </li>
            <li>
              <a href="#">Link 2</a>
            </li>
          </ul>
        </Tab>
        <Tab title="Tab 2" value="2">
          Tab contents 2
        </Tab>
      </Tabs>
    );

    const headers = screen.getAllByRole('tab');

    // Start on the second tab
    userEvent.click(headers[0]);

    // Focus is on tab
    expect(headers[0]).toBe(document.activeElement);

    // Press the TAB key
    userEvent.tab();

    // Focus should now be on the first link in the active tabpanel
    expect(screen.getByText('Link 1')).toBe(document.activeElement);
  });

  it('should correctly honor mountOnEnter', async () => {
    await render(
      <Tabs idPrefix={idPrefix} mountOnEnter>
        <Tab title="Tab 1" value="1">
          <p>Tab contents 1</p>
        </Tab>
        <Tab title="Tab 2" value="2">
          <p>Tab contents 2</p>
        </Tab>
      </Tabs>
    );

    const headers = screen.getAllByRole('tab');

    expect(screen.queryByText('Tab contents 1')).toBeTruthy();
    expect(screen.queryByText('Tab contents 2')).not.toBeTruthy();

    // Switch to tab 2
    userEvent.click(headers[1]);

    // Now both should be present
    await waitFor(() => {
      expect(screen.queryByText('Tab contents 1')).toBeTruthy();
      expect(screen.queryByText('Tab contents 2')).toBeTruthy();
    });
  });

  it('should correctly honor unmountOnExit', async () => {
    await render(
      <Tabs idPrefix={idPrefix} mountOnEnter unmountOnExit>
        <Tab title="Tab 1" value="1">
          <p>Tab contents 1</p>
        </Tab>
        <Tab title="Tab 2" value="2">
          <p>Tab contents 2</p>
        </Tab>
      </Tabs>
    );

    const headers = screen.getAllByRole('tab');

    expect(screen.queryByText('Tab contents 1')).toBeTruthy();
    expect(screen.queryByText('Tab contents 2')).not.toBeTruthy();

    // Switch to tab 2
    userEvent.click(headers[1]);

    await waitFor(() => {
      // Now only the newly active tab should be rendered
      expect(screen.queryByText('Tab contents 1')).not.toBeTruthy();
      expect(screen.queryByText('Tab contents 2')).toBeTruthy();
    });
  });
});

describe('useUniquePrefix hook', () => {
  it('returns unique value with proper prefix', () => {
    const { result } = renderHook(() => useUniquePrefix());

    expect(result.current).toMatch(/cf-tabs-\d+/);
  });
});
