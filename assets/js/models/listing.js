//= require nestoria.js
//= require lib/underscore.js
//= require lib/backbone.js
window.Nestoria.Listing = Backbone.Model.extend({
  initialize: function() {
    this.set("id", this.get("guid"))
  }
})
