import { expect } from 'chai';
import { associateTasksWithAppeals } from '../../../app/queue/utils';

const serverData = {
  tasks: {
    data: [
      {
        attributes: {
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
          assigned_to: {
            css_id: 'BVANKUVALIS',
            id: 130,
            type: 'User'
          },
          case_type: 'Post Remand',
          docket_date: '2008-08-31T00:00:00.000Z',
          docket_name: 'Legacy',
          docket_number: '6182238',
          document_id: '12345-12345678',
          due_on: '2018-08-11T00:00:00.000Z',
          external_appeal_id: '3625593',
          issue_count: 6,
          paper_case: false,
          previous_task: {
            assigned_on: '2018-08-02T17:37:03.000Z'
          },
          task_id: '3625593-2018-07-11',
          action: 'review',
          user_id: 'BVANKUVALIS',
          veteran_file_number: '767574947',
          veteran_name: 'Mills, Beulah, J',
          work_product: 'OTD',
          status: 'Assigned'
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
        appealId: 3,
        externalAppealId: '3625593',
        assignedOn: '2018-08-02T17:37:03.000Z',
        dueOn: '2018-08-11T00:00:00.000Z',
        assignedTo: {
          cssId: 'BVANKUVALIS',
          id: 130,
          type: 'User'
        },
        addedByName: 'Nash X Kuvalis',
        addedByCssId: 'BVANKUVALIS',
        taskId: '3625593-2018-07-11',
        action: 'review',
        documentId: '12345-12345678',
        assignedBy: {
          firstName: 'Stephen',
          lastName: 'Casper',
          cssId: 'BVASCASPER1',
          pgId: 10
        },
        workProduct: 'OTD',
        previousTaskAssignedOn: '2018-08-02T17:37:03.000Z',
        status: 'Assigned'
      }
    });
  });
});
