import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import { connect, useDispatch, useSelector } from 'react-redux';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import QueueTable from '../../queue/QueueTable';
import { dateTimeColumn,
  userColumn,
  activityColumn,
  detailsColumn,
  taskIdColumn } from 'app/nonComp/util/ChangeHistoryColumns';
import { fetchClaimEvents } from '../actions/changeHistorySlice';
import SearchBar from '../../components/SearchBar';

const clearingDivStyling = css({
  borderBottom: `1px solid ${COLORS.GREY_LIGHT}`,
  clear: 'both'
});

const ClaimHistoryGenerator = (props) => {
  const { businessLineUrl } = props;

  const [searchTerm, setSearchTerm] = useState('');

  const dispatch = useDispatch();

  const events = useSelector((state) => state.changeHistory.events);

  useEffect(() => {
    dispatch(fetchClaimEvents({ taskID: 'all', businessLineUrl }));
  }, []);

  const changeHistoryColumns = [
    taskIdColumn(), dateTimeColumn(), userColumn(events), activityColumn(events), detailsColumn()
  ];

  // Filtering logic based on the search term (applies only if searchTerm exists)
  const filteredEvents = searchTerm ?
    events.filter((event) =>
      event.issueType?.toLowerCase()?.includes(searchTerm.toLowerCase()) ||
      event.readableEventType?.toLowerCase()?.includes(searchTerm.toLowerCase())
    ) :
    events;

  // console.log(events);
  // console.log(filteredEvents);

  const onClearSearch = () => {
    setSearchTerm('');
  };

  const handleSearchTermChange = (value) => {
    setSearchTerm(value);
  };

  return <>
    <Link to={`/decision_reviews/${businessLineUrl}`}> &lt; Back to Decision Review </Link>
    <div>
      <section className="cf-app-segment cf-app-segment--alt">
        <div>
          <h1>All History</h1>
          <div {...clearingDivStyling} />
          <div className="cf-search-ahead-parent">
            <SearchBar
              id="searchBar"
              size="small"
              title="Search by stuff"
              onChange={handleSearchTermChange}
              placeholder="Type to search..."
              onClearSearch={onClearSearch}
              isSearchAhead
              value={searchTerm}
            />
          </div>
          <QueueTable
            columns={changeHistoryColumns}
            rowObjects={filteredEvents}
            getKeyForRow={(_rowNumber, event) => event.id}
            defaultSort={{ sortColIdx: 0 }}
            enablePagination
          />
        </div>
      </section>
    </div>
  </>;
};

ClaimHistoryGenerator.propTypes = {
  task: PropTypes.shape({
    id: PropTypes.number,
    claimant: PropTypes.object,
    type: PropTypes.string,
    created_at: PropTypes.string
  }),
  businessLine: PropTypes.string,
  history: PropTypes.shape({
    push: PropTypes.func
  }),
  businessLineUrl: PropTypes.string
};

const ShowAllHistoryPage = connect(
  (state) => ({
    businessLine: state.nonComp.businessLine,
    businessLineUrl: state.nonComp.businessLineUrl
  })
)(ClaimHistoryGenerator);

export default ShowAllHistoryPage;
