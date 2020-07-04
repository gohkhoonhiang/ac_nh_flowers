var latest_data_version = '1fb788e';

var month_names = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec"
];

var flower_types = [
  'Roses',
  'Cosmos',
  'Lilies',
  'Pansies',
  'Tulips',
  'Hyacinths',
  'Mums',
  'Windflowers',
];

var generateDate = function(time_value) {
  var today = new Date();
  var year = today.getFullYear();
  var month = today.getMonth();
  var day = today.getDate();
  var parts = time_value.split(':');
  var hour = parts[0];
  var minute = parts[1];
  return new Date(year, month, day, hour, minute, 0);
};

var hasElement = function(array, value) {
  return array.filter(ele => ele === value).length > 0;
};

var addElement = function(array, value) {
  return array.concat(value);
};

var removeElement = function(array, value) {
  var foundIndex = array.indexOf(value);
  if (foundIndex >= 0) {
    array.splice(foundIndex, 1);
  }
  return array;
};

var app = new Vue({
  el: '#app',
  vuetify: new Vuetify({
    theme: {
      themes: {
        light: {
          primary: '#0ab5cd',
          secondary: '#fffae5',
          header: '#686868',
          toolbar: '#f5f8fe',
          font: '#837865',
          error: '#e76e60',
          invert: '#eee',
        },
      },
    },
  }),

  created() {
    this.retrieveSettings();
    if (this.data_version !== latest_data_version) {
      this.getFlowerData();
      this.data_version = latest_data_version;
    }
    interval = setInterval(() => this.now = new Date(), 1000);
  },

  data: {
    now: new Date(),
    month_names: month_names,
    tab: null,

    data_version: null,

    flower_data: [],
    flower_by_type_data: {},
    flower_headers: [
      { text: 'Type', filterable: false, value: 'type' },
      {
        text: 'Name',
        align: 'start',
        sortable: true,
        filterable: true,
        value: 'name',
      },
      { text: 'Color', filterable: false, value: 'color' },
      { text: 'Parent 1', filterable: false, value: 'parent_1' },
      { text: 'Parent 2', filterable: false, value: 'parent_2' },
      { text: 'Chance %', filterable: false, value: 'chance' },
    ],

    simple_flower_headers: [
      {
        text: 'Name',
        align: 'start',
        sortable: true,
        filterable: true,
        value: 'name',
      },
      { text: 'Parent 1', filterable: false, value: 'parent_1' },
      { text: 'Parent 2', filterable: false, value: 'parent_2' },
      { text: 'Chance %', filterable: false, value: 'chance' },
    ],

    complete_list_row_expanded: [],
    complete_list_row_single_expand: true,

  },

  methods: {
    getFlowerData: function() {
      var vm = this;
      $.ajax({
        url: 'https://raw.githubusercontent.com/gohkhoonhiang/ac_nh_flowers/master/data/complete_flower.json',
        method: 'GET'
      }).then(function (data) {
        var flower_data = JSON.parse(data).data;
        var formatted_data = flower_data.map(function(row) {
          var updated_row = row;
          return updated_row;
        });

        vm.flower_data = formatted_data;
        flower_types.forEach(function(type) {
          vm.flower_by_type_data[type] = vm.filterByType(type);
        });
      });
    },

    filterByType: function(flower_type) {
      var vm = this;
      return vm.flower_data.filter(function(flower) {
        return flower.type === flower_type;
      });
    },

    retrieveSettings: function() {
      var vm = this;
      var settings = JSON.parse(localStorage.getItem('ac_nh_flowers_settings'));
      if (!settings) { return; }

      for (var property in settings) {
        vm[property] = settings[property];
      }
    },

    storeSettings: function() {
      var vm = this;
      var settings = {
        data_version: vm.data_version,
        flower_data: vm.flower_data,
        flower_by_type_data: vm.flower_by_type_data,
      };

      localStorage.setItem('ac_nh_flowers_settings', JSON.stringify(settings));
    },

    resetSettings: function() {
      localStorage.removeItem('ac_nh_flowers_settings');
    },

  },

  watch: {
    data_version: function(new_val, old_val) {
      var vm = this;
      if (new_val !== old_val) {
        vm.storeSettings();
      }
    },

    flower_data: function(new_val, old_val) {
      var vm = this;
      vm.storeSettings();
    },

    flower_by_type_data: function(new_val, old_val) {
      var vm = this;
      vm.storeSettings();
    },

  },

  filters: {
    time_normalized: function(value) {
      if (!value) {
        return '';
      }

      var h = value.getHours();
      var m = value.getMinutes();
      var s = value.getSeconds();
      var parts = [h, m, s];

      var normalized_parts = parts.map(function(part) {
        var i = parseInt(part);
        if (i < 10) {
          return `0${i}`;
        } else {
          return `${i}`;
        }
      });

      return normalized_parts.join(':');
    },

    month_name: function(value) {
      if (!value) {
        return '';
      }

      var month = value.getMonth();
      return month_names[month];
    },

  },
});
