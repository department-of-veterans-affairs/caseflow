import React from 'react';
import TabWindow from 'app/components/TabWindow';
import { render, screen, fireEvent } from '@testing-library/react';
import { tabList } from 'test/data';

/* eslint-disable dot-location */
describe('TabWindow', () => {
  test('Matches snapshot with default props', () => {
    // Set the component
    const {asFragment}=render(<TabWindow tabs={tabList} />);

    // We now expect just one child (the <Tabs> component)
    expect(screen.getByRole('tablist')).toBeInTheDocument();

    const button1 = screen.getByRole('tab', {name: 'Tab 1'});
    expect(button1).toBeInTheDocument();
    expect(button1).toHaveClass('cf-active');
    expect(button1).toHaveAttribute('aria-selected', 'true');
    expect(screen.getByText('Tab 1')).toBeInTheDocument();

    const button2 = screen.getByRole('tab', {name: 'Tab 2'});
    expect(button2).toBeInTheDocument();
    expect(button2).not.toHaveClass('cf-active');
    expect(button2).toHaveAttribute('aria-selected', 'false');
    expect(screen.getByText('Tab 2')).toBeInTheDocument();

    expect(asFragment()).toMatchSnapshot();
  });

  test('Renders an empty div when no tabs are passed', () => {
    // Set the component
    const {asFragment}=render(<TabWindow />);

    const tabListDiv = screen.getByRole('tablist');
    expect(tabListDiv).toBeInTheDocument();
    expect(tabListDiv).toHaveClass('cf-tab-navigation');
    expect(tabListDiv).toHaveTextContent('');

    expect(asFragment()).toMatchSnapshot();
  });

  test('Renders full page when the `fullPage` prop is true', () => {
    // Set the component
    const {container, asFragment}=render(<TabWindow fullPage tabs={tabList} />);

    expect(asFragment()).toMatchSnapshot();
    expect(container.querySelector('.cf-tab-navigation-full-screen')).toBeInTheDocument();
  });

  test('Renders tab content when a tab is selected', () => {
    // Set the component
    const {asFragment}=render(<TabWindow fullPage tabs={tabList} />);

    const button1 = screen.getByRole('tab', {name: 'Tab 1'});
    expect(button1).toBeInTheDocument();
    expect(button1).toHaveClass('cf-active');
    expect(button1).toHaveAttribute('aria-selected', 'true');

    const button2 = screen.getByRole('tab', {name: 'Tab 2'});
    expect(button2).toBeInTheDocument();
    expect(button2).not.toHaveClass('cf-active');
    expect(button2).toHaveAttribute('aria-selected', 'false');

    // Run the test
    fireEvent.click(button2);

    expect(button1).not.toHaveClass('cf-active');
    expect(button1).toHaveAttribute('aria-selected', 'false');

    expect(button2).toHaveClass('cf-active');
    expect(button2).toHaveAttribute('aria-selected', 'true');

    expect(asFragment()).toMatchSnapshot();

  });

  test('Does not render tab content when a tab is disabled and clicked', () => {
    // Set the component
    const {asFragment}=render(
      <TabWindow
        fullPage
        tabs={[
          tabList[0],
          {
            ...tabList[1],
            disable: true,
          },
        ]}
      />
    );

    const button1 = screen.getByRole('tab', {name: 'Tab 1'});
    expect(button1).toBeInTheDocument();
    expect(button1).toHaveClass('cf-active');
    expect(button1).toHaveAttribute('aria-selected', 'true');

    const button2 = screen.getByRole('tab', {name: 'Tab 2'});
    expect(button2).toBeInTheDocument();
    expect(button2).not.toHaveClass('cf-active');
    expect(button2).toHaveAttribute('aria-selected', 'false');

    // Run the test
    fireEvent.click(button2);

    expect(button2).not.toHaveClass('cf-active');
    expect(button2).toHaveAttribute('aria-selected', 'false');

    expect(asFragment()).toMatchSnapshot();
  });

  test('calls onChange when tab changes', () => {
    const onChange = jest.fn();

    // Set the component
    render(<TabWindow onChange={onChange} tabs={tabList} />);

    const button2 = screen.getByRole('tab', {name: 'Tab 2'});

    // Run the test
    fireEvent.click(button2);
    expect(onChange).toHaveBeenCalledWith(1);
  });

  test('renders tabs with one tab if alwaysShowTabs is true', () => {
    render(
      <TabWindow
        tabs={[tabList[0]]}
        alwaysShowTabs
      />
    );

    const button1 = screen.getByRole('tab', {name: 'Tab 1'});
    expect(button1).toBeInTheDocument();

    const button2 = screen.queryByRole('tab', {name: 'Tab 2'});
    expect(button2).not.toBeInTheDocument();
  });
});
/* eslint-enable dot-location */
