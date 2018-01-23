import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter } from 'react-router-dom';
import _ from 'lodash';
import { css } from 'glamor';

import SearchBar from '../components/SearchBar';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/Footer';
import QueueLoadingScreen from './QueueLoadingScreen';
import QueueListView from './QueueListView';
import { COLORS } from './constants';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setSearch, clearSearch } from './QueueActions';

const searchBarStyling = css({
  '.usa-search-big': {
    '> .cf-search-input-with-close': {
      marginLeft: 'calc(100% - 56.5rem)'
    },
    '> span > .cf-submit': {
      width: '10.5rem'
    }
  }
});

class QueueManager extends React.PureComponent {
  routedQueueList = (props) => {
    const { vacolsId } = props.match.params;

    return <QueueLoadingScreen vacolId={vacolsId}>
      <QueueListView {...this.props} />
    </QueueLoadingScreen>;
  };

  render = () => <BrowserRouter basename="/queue">
    <div>
      <NavigationBar
        defaultUrl="/"
        userDisplayName={this.props.userDisplayName}
        dropdownUrls={this.props.dropdownUrls}
        logoProps={{
          backgroundColor: COLORS.QUEUE_LOGO_BACKGROUND,
          overlapColor: COLORS.QUEUE_LOGO_OVERLAP,
          accentColor: COLORS.QUEUE_LOGO_PRIMARY
        }}
        appName="Queue">
        <div className="cf-wide-app section--queue-list">
          {this.props.showSearchBar && <div className="usa-grid">
            <SearchBar
              id="searchBar"
              size="big"
              onSubmit={this.props.setSearch}
              onChange={this.props.setSearch}
              onClearSearch={this.props.clearSearch}
              value={this.props.searchQuery}
              submitUsingEnterKey
              styling={searchBarStyling}
            />
          </div>}
          <PageRoute
            exact
            path="/"
            title="Your Queue | Caseflow Queue"
            render={this.routedQueueList} />
        </div>
      </NavigationBar>
      <Footer
        appName="Queue"
        feedbackUrl={this.props.feedbackUrl}
        buildDate={this.props.buildDate} />
    </div>
  </BrowserRouter>;
}

QueueManager.propTypes = {
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  feedbackUrl: PropTypes.string,
  buildDate: PropTypes.string
};

const mapStateToProps = (state) => _.pick(state, 'showSearchBar', 'filterCriteria.searchQuery');

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setSearch,
  clearSearch
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueManager);
