import React from 'react';
import PropTypes from 'prop-types';

import NonCompLayout from '../components/NonCompLayout';
import TabWindow from '../../components/TabWindow';
import SearchTable from 'app/queue/components/SearchTable';
import { useSelector } from 'react-redux';

const events = {
  savedSearchRows: [
    {
      id: 1,
      name: 'Search Name',
      description: 'Search Description is interesting to be done. Long Desciption goes here. how long is too long',
      createdAt: '2024-07-10',
      userId: 12,
      userCssId: 'VHAADMIN',
      userFullName: 'VHAADMIN',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 2,
      name: 'Search Name2',
      description: 'Search Descriptio2 is interesting to be done.',
      createdAt: '2024-07-11',
      userId: 12,
      userCssId: 'VHAADMIN',
      userFullName: 'VHAADMIN',
      saved_params: {
        report_type: 'event_type_action',
        events: {
          0: 'added_decision_date',
          1: 'added_issue',
          2: 'added_issue_no_decision_date',
          3: 'claim_created',
          4: 'claim_closed'
        },
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 3,
      name: 'Search Name3',
      description: 'Search Description3 is interesting to be done.',
      createdAt: '2024-07-12',
      userId: 13,
      userCssId: 'VHAADMIN2',
      userFullName: 'VHAADMIN2',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 4,
      name: 'Search Name4',
      description: 'Search Description4 is interesting to be done.',
      createdAt: '2024-07-13',
      userId: 14,
      userCssId: 'VHAADMIN3',
      userFullName: 'VHAADMIN3',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 5,
      name: 'Search Name',
      description: 'Search Description is interesting to be done.',
      createdAt: '2024-07-10',
      userId: 12,
      userCssId: 'VHAADMIN',
      userFullName: 'VHAADMIN',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 6,
      name: 'Search Name2',
      description: 'Search Descriptio2 is interesting to be done.',
      createdAt: '2024-07-11',
      userId: 12,
      userCssId: 'VHAADMIN',
      userFullName: 'VHAADMIN',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 7,
      name: 'Search Name3',
      description: 'Search Description3 is interesting to be done.',
      createdAt: '2024-07-12',
      userId: 13,
      userCssId: 'VHAADMIN2',
      userFullName: 'VHAADMIN2',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 8,
      name: 'Search Name4',
      description: 'Search Description4 is interesting to be done.',
      createdAt: '2024-07-13',
      userId: 14,
      userCssId: 'VHAADMIN3',
      userFullName: 'VHAADMIN3',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 9,
      name: 'Search Name',
      description: 'Search Description is interesting to be done.',
      createdAt: '2024-07-10',
      userId: 12,
      userCssId: 'VHAADMIN',
      userFullName: 'VHAADMIN',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 10,
      name: 'Search Name2',
      description: 'Search Descriptio2 is interesting to be done.',
      createdAt: '2024-07-11',
      userId: 12,
      userCssId: 'VHAADMIN',
      userFullName: 'VHAADMIN',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 11,
      name: 'Search Name3',
      description: 'Search Description3 is interesting to be done.',
      createdAt: '2024-07-12',
      userId: 13,
      userCssId: 'VHAADMIN2',
      userFullName: 'VHAADMIN2',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    },
    {
      id: 12,
      name: 'Search Name4',
      description: 'Search Description4 is interesting to be done.',
      createdAt: '2024-07-13',
      userId: 14,
      userCssId: 'VHAADMIN3',
      userFullName: 'VHAADMIN3',
      saved_params: {
        report_type: 'event_type_action',
        timing: {
          range: 'after',
          start_date: '2024-10-07T06:00:00.000Z'
        }
      }
    }
  ]
};

const SavedSearchPage = () => {
  const currentUserCssId = useSelector((state) => state.nonComp.currentUserCssId);

  const ALL_TABS = [
    {
      key: 'my_saved_searches',
      disable: false,
      label: 'My saved searches',
      // this section will later changed to backend call
      page: <SearchTable
        eventRows={events.savedSearchRows.filter((rows) => rows.userCssId === currentUserCssId)}
        searchPageApiEndPoint
      />
    },
    {
      key: 'all_saved_searches',
      disable: false,
      label: 'All saved searches',
      page: <SearchTable
        eventRows={events.savedSearchRows}
        searchPageApiEndPoint
      />
    }
  ];

  return (
    <NonCompLayout>
      <h1>Saved Searches</h1>
      <div>Select a search you previously saved or look for ones others have saved by switching between tabs.</div>
      <TabWindow name="saved-search-queue" tabs={ALL_TABS} />
    </NonCompLayout>
  );
};

SavedSearchPage.propTypes = {
  history: PropTypes.object,
};

export default SavedSearchPage;
