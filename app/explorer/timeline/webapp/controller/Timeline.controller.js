sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel"
], function (Controller, JSONModel) {
  "use strict";

  // Reisstatus -> kleurtype voor de kalender-afspraak
  var STATUS_TYPE = { Gepland: "Type07", Onderweg: "Type04", Afgerond: "Type02" };

  return Controller.extend("primepath.explorer.timeline.controller.Timeline", {

    onInit: function () {
      var oModel = this.getOwnerComponent().getModel();
      var oBinding = oModel.bindList("/Trips");

      oBinding.requestContexts(0, 1000).then(function (aContexts) {
        var mRows = {};
        var dEarliest = null;

        aContexts.forEach(function (oCtx) {
          var t = oCtx.getObject();
          var sOwner = t.Owner || "Onbekend";
          if (!mRows[sOwner]) {
            mRows[sOwner] = { title: sOwner, text: "Medewerker", appointments: [] };
          }
          var dStart = t.StartsAt ? new Date(t.StartsAt) : null;
          var dEnd = t.EndsAt ? new Date(t.EndsAt) : null;
          if (dStart && (!dEarliest || dStart < dEarliest)) {
            dEarliest = dStart;
          }
          mRows[sOwner].appointments.push({
            name: t.Name || ("Reis " + t.TripId),
            status: t.Status,
            start: dStart,
            end: dEnd,
            type: STATUS_TYPE[t.Status] || "Type10"
          });
        });

        var aRows = Object.keys(mRows).map(function (k) { return mRows[k]; });
        this.getView().setModel(new JSONModel({
          startDate: dEarliest || new Date(),
          rows: aRows
        }));
      }.bind(this)).catch(function (oErr) {
        sap.ui.require(["sap/m/MessageToast"], function (MessageToast) {
          MessageToast.show("Laden van reizen mislukt: " + (oErr.message || oErr));
        });
      });
    }
  });
});
