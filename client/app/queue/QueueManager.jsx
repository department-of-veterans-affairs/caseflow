import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import { getQueryParams } from '../util/QueryParamsUtil';
import _ from 'lodash';

import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';
import QueueLoadingScreen from './QueueLoadingScreen';
import QueueListView from './QueueListView';
import SearchBar from '../components/SearchBar';

import { setSearch, clearSearch } from './QueueActions';

class QueueManager extends React.PureComponent {
  routedQueueList = (props) => {
    const { vacolsId } = props.match.params;

    return <QueueLoadingScreen vacolsId={vacolsId}>
      <QueueListView {...props} />
    </QueueLoadingScreen>;
  };

  routedQueueDetail = (props) => {
    debugger;
  };

  render = () => {
    return <BrowserRouter basename="/queue">
      <div>
        <NavigationBar
          defaultUrl="/"
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
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
              />
            </div>}
            <PageRoute
              exact
              path="/"
              title="Your Queue | Caseflow Queue"
              render={this.routedQueueList}/>
            <PageRoute
              exact
              path="/detail/:decision_id"
              title="Draft Decision | Caseflow Queue"
              render={this.routedQueueDetail}/>
          </div>
        </NavigationBar>
        <Footer
          appName="Queue"
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate}/>
      </div>
    </BrowserRouter>;
  };
}

QueueManager.propTypes = {
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  feedbackUrl: PropTypes.string,
  buildDate: PropTypes.string
};

const mapStateToProps = (state) => ({
  ..._.pick(state, 'showSearchBar'),
  searchQuery: state.filterCriteria.searchQuery
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setSearch,
    clearSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(QueueManager);
