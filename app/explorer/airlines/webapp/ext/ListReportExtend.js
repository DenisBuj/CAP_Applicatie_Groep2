sap.ui.define([], function () {
  "use strict";

  // Custom List Report-actie: opent het KPI-/kerncijferoverzicht (FR-001).
  // De KPISummary is een singleton-ObjectPage die alleen betrouwbaar bindt als
  // ze via haar eigen route wordt geopend (niet als koude landingspagina).
  // Daarom is de Airlines-lijst de landingspagina en navigeren we hierheen.
  return {
    openKPIOverview: function () {
      // `this` = sap.fe.core.ExtensionAPI van het List Report.
      // Defensief: de routing-API zit op .routing of via .getRouting().
      var oRouting = this.routing || (this.getRouting && this.getRouting());
      if (oRouting && oRouting.navigateToRoute) {
        oRouting.navigateToRoute("KPISummaryPage");
      }
    }
  };
});
