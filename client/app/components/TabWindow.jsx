import React, { PropTypes } from 'react';

/*
 * This component can be used to easily build tabs.
 * The required props are:
 * - @tabs {array[string]} array of strings placed in the tabs at the top
 * of the window
 * - @pages {array[node]} array of nodes displayed when the corresponding
 * tab is selected
*/
export default class TabWindow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      currentPage: 0,
      disabled: false
    };
  }

  onTabClick = (tabNumber) => () => {
    this.setState({
      currentPage: tabNumber
    });

    if (this.props.onChange) {
      this.props.onChange(tabNumber);
    }
  }

  onDisabledTabClick = (tab) => () => {
    if (Boolean(tab.disable) === true) {
      this.setState({
        disabled: true
      });
    }
  }

  getTabHeaderWithSVG = (tab) => {
    return <span>
      {tab.icon ? tab.icon : ''}
      <span>{tab.label}</span>
    </span>;
  }

  getTabClassName = (index, currentPage, isTabDisabled) => {
    let className = "";

    className = `cf-tab${index === currentPage ? " cf-active" : ""}`;
    className += isTabDisabled ? ' disabled' : '';

    return className;
  }

  render() {
    let {
      tabs,
      pages,
      fullPage
    } = this.props;

    let newTabs = [];


    tabs.map((tab) => {
      newTabs.push({ disable: tab.disable,
        element: this.getTabHeaderWithSVG(tab) });

      return newTabs;
    });

    return <div>
        <div className={
          `cf-tab-navigation${fullPage ? " cf-tab-navigation-full-screen" : ""}`
        }>
          {newTabs.map((tab, i) =>
            <button
              className={this.getTabClassName(i, this.state.currentPage, tab.disable)}
              key={i}
              id={`tab-${i}`}
              onClick={tab.disable ? this.onDisabledTabClick(i) : this.onTabClick(i)}
              disabled={Boolean(tab.disable)}>
              <span>
                {tab.element}
              </span>
            </button>
          )}
        </div>
        <div className="cf-tab-window-body-full-screen">
          {pages[this.state.currentPage]}
        </div>
      </div>;
  }
}

TabWindow.propTypes = {
  onChange: PropTypes.func,
  pages: PropTypes.arrayOf(PropTypes.node).isRequired,
  tabs: PropTypes.arrayOf(PropTypes.object)
};
