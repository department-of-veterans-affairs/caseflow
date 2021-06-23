import { expect } from 'chai';
import { associateTasksWithAppeals } from '../../../app/queue/utils';

const serverData = {
  tasks: {
    data: [
      {
        attributes: {
          is_legacy: true,
          type: 'LegacyJudgeTask',
          appeal_type: 'LegacyAppeal',
          added_by_css_id: 'BVANKUVALIS',
          added_by_name: 'Nash X Kuvalis',
          aod: false,
          appeal_id: 3,
          assigned_by: {
            first_name: 'Stephen',
            last_name: 'Casper',
            css_id: 'BVASCASPER1',
            pg_id: 10
          },
          assigned_on: '2018-08-02T17:37:03.000Z',
          closed_at: null,
          assigned_to: {
            css_id: 'BVANKUVALIS',
            name: 'name',
            id: 130,
            isOrganization: false,
            type: 'User'
          },
          case_type: 'Post Remand',
          docket_date: '2008-08-31T00:00:00.000Z',
          docket_name: 'Legacy',
          docket_number: '6182238',
          document_id: '12345-12345678',
          external_appeal_id: '3625593',
          issue_count: 6,
          paper_case: false,
          previous_task: {
            assigned_on: '2018-08-02T17:37:03.000Z'
          },
          started_at: '2018-08-02T17:37:03.000Z',
          task_id: '3625593-2018-07-11',
          label: 'Review',
          user_id: 'BVANKUVALIS',
          veteran_file_number: '767574947',
          veteran_name: 'Mills, Beulah, J',
          work_product: 'OTD',
          status: 'Assigned',
          hide_from_queue_table_view: false,
          hide_from_case_timeline: false,
          hide_from_task_snapshot: false,
          latest_informal_hearing_presentation_task: {}
        },
        id: '3625593',
        type: 'judge_legacy_tasks'
      }
    ]
  }
};

describe('QueueLoadingScreen', () => {
  it('associates queue decisions/appeals and tasks', () => {
    const { tasks } = associateTasksWithAppeals(serverData);

    expect(tasks).to.deep.equal({
      3625593: {
        uniqueId: '3625593',
        isLegacy: true,
        appealId: 3,
        appealType: 'LegacyAppeal',
        externalAppealId: '3625593',
        assignedOn: '2018-08-02T17:37:03.000Z',
        closedAt: null,
        assignedTo: {
          cssId: 'BVANKUVALIS',
          name: 'name',
          id: 130,
          type: 'User',
          // eslint-disable-next-line no-undefined
          isOrganization: undefined
        },
        assigneeName: undefined,
        // eslint-disable-next-line no-undefined
        availableActions: undefined,
        // eslint-disable-next-line no-undefined
        timelineTitle: undefined,
        addedByName: 'Nash X Kuvalis',
        addedByCssId: 'BVANKUVALIS',
        taskId: '3625593-2018-07-11',
        label: 'Review',
        documentId: '12345-12345678',
        assignedBy: {
          firstName: 'Stephen',
          lastName: 'Casper',
          cssId: 'BVASCASPER1',
          pgId: 10
        },
        workProduct: 'OTD',
        previousTaskAssignedOn: '2018-08-02T17:37:03.000Z',
        startedAt: '2018-08-02T17:37:03.000Z',
        status: 'Assigned',
        decisionPreparedBy: null,
        type: 'LegacyJudgeTask',
        hideFromQueueTableView: false,
        hideFromCaseTimeline: false,
        hideFromTaskSnapshot: false,
        latestInformalHearingPresentationTask: {
          requestedAt: undefined,
          receivedAt: undefined
        }
      }
    });
  });
});
