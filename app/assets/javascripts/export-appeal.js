//= require jquery
//= require vis-network/dist/vis-network.min.js
//= require vis-timeline/dist/vis-timeline-graph2d.min.js

/**
 * Support code for app/views/export/show.html.erb,
 * associated with app/controllers/export_controller.rb.
 * Also see accompanying app/assets/stylesheets/export_appeal.css.
 * These are added to the application in config/initializers/assets.rb.
 */

const taskNodeColor = {
  assigned: "#00dd00",
  in_progress: "#00ff00",
  on_hold: "#cccc00",
  cancelled: "#8a8",
  completed: "#00bb00"
}

// See icons at https://fontawesome.com/icons
const nodeDecoration = {
  intakes: { shape: "diamond" },
  cavc_remands: { shape: "triangle" },
  appeals: { shape: "star", size: 30, color: "#ff8888" },
  claimants: { shape: "ellipse", color: "#d3d3d3" },
  veterans: { shape: "icon", icon: { code: "\uf29a" } },
  people: { shape: "icon", icon: { code: "\uf2bb", color: "gray" } },
  users: { shape: "icon", size: 10, icon: { code: "\uf007", color: "gray" } },
  organizations: { shape: "icon", icon: { code: "\uf0e8", color: "#a3a3a3" } },
  tasks: { shape: "box", color: (node)=>taskNodeColor[node.status] },
  request_issues: { shape: "box", color: "#ffa500" },
  decision_issues: { shape: "box", color: "#ffe100" },
  decision_documents: { shape: "icon", icon: { code: "\uf15b", color: "#660000" } },
  attorney_case_reviews: { shape: "icon", icon: { code: "\uf07a", color: "#660033" } },
  judge_case_reviews: { shape: "icon", icon: { code: "\uf07a", color: "#660000" } }
};

function decorateNodes(nodes){
  nodes.forEach(node => {
    if(!nodeDecoration.hasOwnProperty(node.tableName)) return;
    for ([key, value] of Object.entries(nodeDecoration[node.tableName])) {
      if (typeof value === 'function') {
        value = value(node)
      }
      node[key] = value
    }
  });
  // console.log(nodes)
  return nodes;
}

const nodesFilterValues = {};

function addNetworkGraph(elementId, network_graph_data){
  const nodesFilter = (node) => {
    visible = nodesFilterValues[node.tableName];
    return visible === undefined ? true : visible
  };
  const edgesFilter = (edge) => {
    return true;
  };

  const nodesData = new vis.DataSet(decorateNodes(network_graph_data["nodes"]));
  const edgesData = new vis.DataSet(network_graph_data["edges"]);

  const nodesView = new vis.DataView(nodesData, { filter: nodesFilter });
  const edgesView = new vis.DataView(edgesData, { filter: edgesFilter });
  const network_options = {
    width: '95%',
    height: '500px',
    edges: {
      arrows: 'to'
    },
    interaction: {
      zoomSpeed: 0.2
    }
  };

  $('#nodeFilters input').change(function(){
    nodesFilterValues[this.name] = this.checked;
    nodesView.refresh();
  });

  const netgraph = document.getElementById(elementId);
  return new vis.Network(netgraph, { nodes: nodesView, edges: edgesView }, network_options);
}

const itemDecoration = {
  tasks: { style: (item)=>"background-color: "+taskNodeColor[item.status] }
};

function decorateTimelineItems(items){
  items.forEach(item => {
    if(!itemDecoration.hasOwnProperty(item.tableName)) return;
    for ([key, value] of Object.entries(itemDecoration[item.tableName])) {
      if (typeof value === 'function') {
        value = value(item)
      }
      item[key] = value
    }
  });
  // console.log(items)
  return items;
}

function addTimeline(elementId, timeline_data){
  const timeline = document.getElementById(elementId);
  const items = new vis.DataSet(decorateTimelineItems(timeline_data));
  const timeline_options = {
    width: '95%'
  };
  new vis.Timeline(timeline, items, timeline_options);
}
