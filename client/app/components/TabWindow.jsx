import React, { PropTypes } from 'react';

/**
 * This component can be used to easily build tabs.
 * There required props are:
 * - @tabs {array[string]} array of strings placed the tabs at the top
 * of the window
 * - @pages {array[node]} array of nodes displayed when the corresponding
 * tab is selected
 *
*/
export default class TabWindow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      currentPage: 0
    };
  }

  onTabClick = (tabNumber) => (event) => {
    this.setState({
      currentPage: tabNumber
    });

    if (this.props.onChange) {
      this.props.onChange(tabNumber);
    }
  }

  render() {
    let {
      tabs,
      pages
    } = this.props;

    return <div>
        <div className="cf-tab-navigation cf-tab-navigation-full-screen">
          {tabs.map((tab, i) =>
            <div
              className={`cf-tab${i === this.state.currentPage ? " cf-active" : ""}`}
              key={i}
              onClick={this.onTabClick(i)}>
              {tab}
            </div>
          )}
        </div>
        <div className="cf-tab-window-body-full-screen">
          {pages[this.state.currentPage]}
        </div>
      </div>;
  }
}

TabWindow.propTypes = {
  tabs: PropTypes.arrayOf(PropTypes.string).isRequired,
  onChange: PropTypes.func,
  pages: PropTypes.arrayOf(PropTypes.node).isRequired
};
