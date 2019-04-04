/*
Copyright (c) 2016, BrightPoint Consulting, Inc.

This source code is covered under the following license: http://vizuly.io/license/

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

// @version 1.1.54

//**************************************************************************************************************
//
//  This is a test/example file that shows you one way you could use a vizuly object.
//  We have tried to make these examples easy enough to follow, while still using some more advanced
//  techniques.  Vizuly does not rely on any libraries other than D3.  These examples do use jQuery and
//  materialize.css to simplify the examples and provide a decent UI framework.
//
//**************************************************************************************************************


var viz;            // vizuly ui object
var viz_container;  // html element that holds the viz (d3 selection)
var viz_title;      // title element (d3 selection)
var theme;          // Theme variable to be used by our viz.

var data;           // Holds the currently used data (senate or house)
var dataSource={};  // Object holds both senate and house data sources.

// D3 formatters we will use for labels
var formatDate = d3.time.format("%b %d, 20%y");

function loadData(task_id) {

    // Here we grab our data via the <code>d3.json</code> utility.
    d3.csv("/bubbleplot_data/" + task_id, function (csv) {

        dataSource.house=csv;
        data=csv;
        initialize();

    });
}

//Initializes chart and container.
function initialize() {

    // Here we set our <code>viz</code> variable by instantiating the <code>vizuly.viz.corona</code> function.
    // All vizuly components require a parent DOM element at initialization so they know where to inject their display elements.
    viz = vizuly.viz.halo_cluster(document.getElementById("viz_container"));

    viz.data(data)
        .width(800).height(600)                     // Initial display size
        .haloKey(function (d) {
            return d.Source; })                    // The property that determines each PAC
        .nodeKey(function (d) {
            return d.ASV; })                    // The property that determines Candidate
        .nodeGroupKey(function (d) {
            return d.MATCH; })                        // The property that determines candidate Party affiliation
        .value(function (d) {
            return Number(d.RelativeAbundanceWEIGHT); })    // The property that determines the weight/size of the link path
        .on("update", onUpdate)                     // Callback for viz update
        .on("nodeover",node_onMouseOver)            // Callback for mouseover on the candidates
        .on("nodeout",onMouseOut)                   // Callback for mouseout on from the candidate
        .on("arcover",arc_onMouseOver)              // Callback for mouseover on each PAC
        .on("arcout",onMouseOut)                    // Callback for mouseout on each PAC
        .on("linkover",link_onMouseOver)            // Callback for mousover on each contribution
        .on("linkout",onMouseOut)                   // Callback for mouseout on each contribution
        .on("nodeclick",node_onClick)

    //** Themes and skins **  play a big role in vizuly, and are designed to make it easy to make subtle or drastic changes
    //to the look and feel of any component.   Here we choose a theme and skin to use for our bar chart.
    // *See this <a href=''>guide</a> for understanding the details of themes and skins.*
    theme = vizuly.theme.halo(viz);

    // This example shows how you can use a custom skin and add it to the theme.
    // You can see how this skin is made at the end of this file.
    theme.skins()["custom"]=customSkin;
    theme.skin("custom");

    //The <code>viz.selection()</code> property refers to the parent
    //container that was used at the object construction.  With this <code>selection</code> property we can use D3
    //add, remove, or manipulate elements within the component.  In this case we add a title label and heading to our chart.
    viz_title = viz.selection().select("svg").append("text").attr("class", "title")
        .style("font-family","Raleway")
        .attr("x", viz.width() / 2).attr("y", 40).attr("text-anchor", "middle").style("font-weight",300).text("");

    //Update the size of the component
    changeSize(d3.select("#currentDisplay").attr("item_value"));

    /*
    // This code is for the purposes of the demo and simply cycles through the various skins
    // The user can stop this by clicking anywhere on the page.
    var reel = vizuly.showreel(theme,['Fire','Sunset','Neon','Ocean','custom'],2000).start();
    d3.select("body").on("mousedown.reel",function () {
        //Stop show reel
        reel.stop();
        //Remove event listener
        d3.select("body").on("mousedown.reel",null);
    })
    */
}

// Each time the viz is updated we adjust our title color
// Do a little tweak for our custom skin.
function onUpdate() {
    viz_title.style("fill", (theme.skin() != customSkin) ? theme.skin().labelColor : "#000");
}

// An example of how you could respond to a node click event
function node_onClick(e,d,i) {
    // console.log("You have just clicked on " + d.values[0].ASV);
}

// For each mouse over on the node we want to create a datatip that shows information about the candidate
// and any assoicated PACs that have contributed to the candidate.
function node_onMouseOver(e,d,i) {

    //Find all node links (candidates) and create a label for each arc
    var haloLabels={};
    var links=viz.selection().selectAll(".vz-halo-link-path.node-key_" + d.key);
    var total=0;
    var count=0;


    //For each link we want to dynamically total the transactions to display them on the datatip.
    links.each(function (d) {
        total+= parseFloat(d.data.RelativeAbundanceSource);
         count += parseFloat(d.data.CountWEIGHT);
        var halos=viz.selection().selectAll(".vz-halo-arc.halo-key_" + viz.haloKey()(d.data));
        halos.each(function (d) {
            if (!haloLabels[d.data.key]) {
                haloLabels[d.data.key]=1;
                createPacLabel(d.x, d.y,d.data.values[0].Source);
            }
        })
    });

    //Format the label for the datatip.
    total = d3.format(",.1f")(total) + "% (";
    count = d3.format(",.0f")(count) + " total reads)";

    //Create and position the datatip
    var rect = d3.selectAll(".vz-halo-arc-plot")[0][0].getBoundingClientRect();

    var node = viz.selection().selectAll(".vz-halo-node.node-key_" + d.key);
    //Create and position the datatip
    var rect = node[0][0].getBoundingClientRect();

    var x = rect.left;
    var y = rect.top + parseFloat($(window).scrollTop());

    createDataTip(x + d.r, y + d.r + 25, "ASV", d.values[0].ASV, "Relative abundance: " + total + count);
}

// For each PAC we want to create a datatip that shows the total of all contributions by that PAC
function arc_onMouseOver(e,d,i) {

    //Find all links from a PAC and create totals
    var links=viz.selection().selectAll(".vz-halo-link-path.halo-key_" + d.data.key);
    var total=0;
    var total_weight = 0;
    links.each(function (d) {
        total_weight += parseFloat(d.data.SourceContributionWEIGHT);
        total+= viz.value()(d.data);
    });

    total = d3.format(",.1f")(total) + "%" ;
    total_weight = d3.format(",.1f")(total_weight) + "%" ;

    //Create and position the datatip
    var rect = d3.selectAll(".vz-halo-node-plot")[0][0].getBoundingClientRect();
    createDataTip(d.x + rect.left + rect.width/2, (d.y + rect.top + 100 + parseFloat($(window).scrollTop())),"Source", d.data.values[0].Source,"Source contribution: " + total_weight);
}

// When the user rolls over a link we want to create a lable for the PAC and a data tip for the candidate that the
// contribution went to.
function link_onMouseOver(e,d,i) {

    // find the associated candidate and get values for the datatip
    var cand=viz.selection().selectAll(".vz-halo-node.node-key_" + viz.nodeKey()(d.data));
    var datum=cand.datum();
    var total = d3.format(",.1f")(parseFloat(d.data.RelativeAbundanceSource)) + "%" ; 
    var date = d.data.Month + "/" + d.data.Day + "/" + d.data.Year;

    //Create and position the datatip
    var rect = d3.selectAll(".vz-halo-arc-plot")[0][0].getBoundingClientRect();
    createDataTip(datum.x + rect.left + datum.r, datum.y + datum.r + 25 + rect.top + parseFloat($(window).scrollTop()), "ASV", d.data.ASV,"Relative abundance within source: " + total);

    //find the pac and create a label for it.
    var pac=viz.selection().selectAll(".vz-halo-arc.halo-key_" + viz.haloKey()(d.data));
    datum=pac.datum();
    createPacLabel(datum.x, datum.y,datum.data.values[0].Source);
}

//Here is a template for our data tip
var datatip='<div class="vz-tooltip" style="width: 250px; background-opacity:.5">' +
    '<div class="header1">HEADER1</div>' +
    '<div class="header-rule"></div>' +
    '<div class="header2"> HEADER2 </div>' +
    '<div class="header-rule"></div>' +
    '<div class="header3"> HEADER3 </div>' +
    '</div>';

// This function uses the above html template to replace values and then creates a new <div> that it appends to the
// document.body.  This is just one way you could implement a data tip.
function createDataTip(x,y,h1,h2,h3) {

    var html = datatip.replace("HEADER1", h1);
    html = html.replace("HEADER2", h2);
    html = html.replace("HEADER3", h3);

    d3.select("body")
        .append("div")
        .attr("class", "vz-halo-label")
        .style("position", "absolute")
        .style("top", y + "px")
        .style("left", (x - 125) + "px")
        .style("opacity",0)
        .html(html)
        .transition().style("opacity",1);

}

// This function creates a highlight label with the PAC name when an associated link or candidate has issued a mouseover
// event.  It uses properties from the skin to determine the specific style of the label.
function createPacLabel (x,y,l) {

    var g = viz.selection().selectAll(".vz-halo-arc-plot").append("g")
        .attr("class","vz-halo-label")
        .style("pointer-events","none")
        .style("opacity",0);

    g.append("text")
        .style("font-size","11px")
        .style("fill",theme.skin().labelColor)
        .style("fill-opacity",.75)
        .attr("text-anchor","middle")
        .attr("x", x)
        .attr("y", y)
        .text(l);

    var rect = g[0][0].getBoundingClientRect();
    g.insert("rect","text")
        .style("shape-rendering","auto")
        .style("fill",theme.skin().labelFill)
        .style("opacity",.45)
        .attr("width",rect.width+12)
        .attr("height",rect.height+12)
        .attr("rx",3)
        .attr("ry",3)
        .attr("x", x-5 - rect.width/2)
        .attr("y", y - rect.height-3);

    g.transition().style("opacity",1);
}

// When we mouse out we want to remove all pac datatips and labels.
function onMouseOut(d,i) {
    d3.selectAll(".vz-halo-label").remove();
}

//
// This is an example of defining a custom skin that creates a different look than the stock ones.
// We want to create a skin that shows the relative political parties by using the party colors
// republican = red and democrat = blue
//
// You can see how we attach and set this skin in the initialize routine at the top of this file with these two lines
//   theme.skins()["custom"]=customSkin;
//   theme.skin("custom");
//

// Set the match colors
var repColor="#F80018";     // when doesnt match with classifiers
var demColor="#0a4f75";     // when match
var otherColor="#FFa400";

// Create a skin object that has all of the same properties as the skin objects in the /themes/halo.js vizuly file
var customSkin = {
    name: "custom",
    labelColor: "#FFF",
    labelFill: "#000",
    background_transition: function (selection) {
        viz.selection().select(".vz-background").transition(1000).style("fill-opacity", 0);
    },
    // Here we set the contribution colors based on the party
    link_stroke: function (d, i) {
        return (d.data.MATCH == "no") ? repColor : (d.nodeGroup="yes") ? demColor: otherColor;
    },
    link_fill: function (d, i) {
        return (d.data.MATCH == "no") ? repColor : (d.nodeGroup="yes") ? demColor: otherColor;
    },
    link_fill_opacity:.2,
    link_node_fill_opacity:.5,
    node_stroke: function (d, i) {
        return "#FFF";
    },
    node_over_stroke: function (d, i) {
        return "#FFF";
    },
    // Here we set the candidate colors based on the party
    node_fill: function (d, i) {
        return (d.nodeGroup == "no") ? repColor : (d.nodeGroup=="yes") ? demColor: otherColor;
    },
    arc_stroke: function (d, i) {
        return "#FFF";
    },
    // Here we set the arc contribution colors based on the party
    arc_fill: function (d, i) {
        return (d.data.MATCH == "no") ? repColor : (d.nodeGroup=="yes") ? demColor: otherColor;
    },
    arc_over_fill: function (d, i) {
        return "#000";
    },
    class: "vz-skin-political-influence"
}

//
// Functions used by the test container to set various properties of the viz
//
function changeSkin(val) {
    if (!val) return;
    theme.skin(val);
    viz.update();
}

function changeSize(val) {
    var s = String(val).split(",");
    viz_container.transition().duration(300).style('width', s[0] + 'px').style('height', s[1] + 'px');
    viz.width(Number(s[0])).height(Number(s[1])).update();
    viz_title.attr("x", viz.width() / 2);
    theme.apply();
}

var congress="House";
function changeData(val) {
    congress=val;
    data=dataSource[val];
    viz.data(data).update();
}








