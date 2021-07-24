//= require vis-data/peer/umd/vis-data.min.js
//= require vis-network/peer/umd/vis-network.min.js
// See https://visjs.github.io/vis-network/examples/network/basic_usage/peer.html

/**
 * Support code for app/views/explain/show.html.erb,
 * associated with app/controllers/explain_controller.rb.
 * Also see accompanying app/assets/stylesheets/explain_appeal.css.
 * These are added to the application in config/initializers/assets.rb.
 */

//================== Network graph ========================

// These colors should match with those in export-appeal.css
const taskNodeColor = {
  assigned: "#FFFF80",
  on_hold: "#A3A303",
  in_progress: "#00FF00",
  completed: "#00B800",
  cancelled: "#D89696"
}

// See icons at https://fontawesome.com/icons
const nodeDecoration = {
  intakes: { shape: "diamond" },
  cavc_remands: { shape: "triangle" },
  appeals: { shape: "star", size: 30, color: "blue", mass: 10 },
  claimants: { shape: "ellipse", color: "#d3d3d3" },
  veterans: { shape: "icon", icon: { code: "\uf29a" } },
  people: { shape: "icon", icon: { code: "\uf2bb", color: "gray" } },
  users: { shape: "icon", icon: { code: "\uf007", color: "gray" } },
  organizations: { shape: "icon", icon: { code: "\uf0e8", color: "#a3a3a3" }, mass: 4 },
  tasks: { shape: "box", color: (node)=>taskNodeColor[node.status],
           shapeProperties: { borderRadius: 1 }
         },
  request_issues: { shape: "ellipse", color: "#ffa500" },
  decision_issues: { shape: "ellipse", color: "#ffe100" },
  decision_documents: { shape: "icon", icon: { code: "\uf15b", color: "#660000" } },
  attorney_case_reviews: { shape: "icon", icon: { code: "\uf07a", color: "#660033" } },
  judge_case_reviews: { shape: "icon", icon: { code: "\uf07a", color: "#660000" } }
};

// Using decorateNodes instead of CSS styles because the graph is in a canvas and
// the color is part of the shape and icon.
function decorateNodes(nodes){
  nodes.forEach(node => {
    if(!nodeDecoration.hasOwnProperty(node.tableName)) return;

    for ([key, value] of Object.entries(nodeDecoration[node.tableName])) {
      if (typeof value === 'function') {
        value = value(node)
      }
      node[key] = value
    }

    // `node.title` is displayed as the tooltip on node mouseover
    if(!node.title){
      node.title = formatJson(node);
    }
  });
  // console.log(nodes)
  return nodes;
}

const nodesFilterValues = {};

// Define filters needed to dynamically filter nodes from the network graph visualization.
const nodesFilter = (node) => {
  visible = nodesFilterValues[node.tableName];
  return visible === undefined ? true : visible
};
const edgesFilter = (edge) => {
  return true;
};

const nodesData = new vis.DataSet();
const edgesData = new vis.DataSet();

const nodesView = new vis.DataView(nodesData, { filter: nodesFilter });
const edgesView = new vis.DataView(edgesData, { filter: edgesFilter });

function addNetworkGraph(elementId, network_graph_data){
  nodesData.add(decorateNodes(network_graph_data["nodes"]));
  edgesData.add(network_graph_data["edges"])
  // https://visjs.github.io/vis-network/docs/network/#options
  const network_options = {
    width: '95%',
    height: '800px',
    edges: {
      arrows: 'to'
    },
    interaction: {
      zoomSpeed: 0.2
    }
  };

  const netgraph = document.getElementById(elementId);
  return new vis.Network(netgraph, { nodes: nodesView, edges: edgesView }, network_options);
}

function toggleNodeType(checkbox){
  nodesFilterValues[checkbox.value] = checkbox.checked;
  nodesView.refresh();
}
