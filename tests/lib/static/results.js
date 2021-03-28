function Results($scope, $http, $timeout) {
  var self = this;

  $scope.status = { status: "loading..." }

  self.load_status = function() {
    $http.get('api/status').success(function(data) {

      $scope.status = data;

      if (data.status == "running") {
        $timeout(self.load_status, 500);
      }

    }).
    error(function(data, s) {
      console.log("error on load!");
      console.log(data);
      console.log(s);
      $scope.status = { status: "error" }
    });
  }

  $scope.selected = 0;
  $scope.is_selected = function(idx) {
    return idx == $scope.selected;
  }

  $scope.select = function(idx) {
    $scope.selected = idx;
  }

  $scope.run = function() {
    $scope.status = { status: "loading..." };
    $http.post('api/run').success(function() {
      self.load_status();
    });
  }

  $scope.run_one = function(index) {
    $scope.status.status = "loading...";
    var tc = $scope.status.test_cases[index];
    $http.post('api/run_one' + tc).success(function() {
      self.load_status();
    });
  };

  $scope.status_as_severity = function() {
    var severities = { "loading...": "info"
                     , "not_run_yet": "info"
                     , "running": "warning"
                     , "ran": "success"
                     , "error": "important"
                     };
    return severities[$scope.status.status];
  };

  $scope.status_as_label = function() {
    return $scope.status.status.replace(/_/g, " ");
  };

  $scope.percent_tests_success = function() {
    if ("test_cases" in $scope.status && "test_results" in $scope.status) {

      var count = 0;
      for(key in $scope.status.test_results) {
        var value = $scope.status.test_results[key];
        if (value.passed) {
          count++;
        }
      }
      return 100 * count / $scope.status.test_cases.length;
    }
    return 0;
  }

  $scope.percent_tests_partial_success = function() {
    if ("test_cases" in $scope.status && "test_results" in $scope.status) {
      var count = 0;
      for(key in $scope.status.test_results) {
        var value = $scope.status.test_results[key];
        var e = value.emulator.passed;
        var a = value.assembler.passed;

        if ((e || a) && !(e && a)) {
          count++;
        }
      }
      return 100 * count / $scope.status.test_cases.length;
    }
    return 0;
  }

  $scope.percent_tests_failure = function() {
    if ("test_cases" in $scope.status && "test_results" in $scope.status) {
      var count = 0;
      for(key in $scope.status.test_results) {
        var value = $scope.status.test_results[key];
        var e = value.emulator.passed;
        var a = value.assembler.passed;

        if (!e && !a) {
          count++;
        }
      }
      return 100 * count / $scope.status.test_cases.length;
    }
    return 0;
  }

  $scope.test_case_as_severity = function(name) {
    if ("test_results" in $scope.status) {
      result = $scope.status.test_results[name];
      if (result) {
        if (result.passed) {
            return "success";
        }
        return "important";
      }

      return "warning";
    }
  }

  $scope.test_case_subpart_as_severity = function(name, part) {
    if ("test_results" in $scope.status) {
      result = $scope.status.test_results[name];

      if (result && result[part]) {
        if (result[part]['passed']) {
          return "success";
        }
        return "important";
      }

      return "warning";
    }
  }

  $scope.test_case_as_label = function(name) {
    var match = /(.*)\/(.*?)$/.exec(name);
    return match[2];
  }

  self.load_file = function(cache, prefix, name) {
    if (name in $scope[cache]) {
      return $scope[cache][name];
    }

    $scope[cache][name] = "Loading...";

    $http.get(prefix + name).success(function(content) {
      $scope[cache][name] = content;
    });

    return $scope[cache][name];
  }


  $scope.test_case_source_file = function(source_file) {
    return self.load_file('source_files', '/files/source', source_file);
  }

  $scope.test_case_binary_file = function(binary_file) {
    return self.load_file('binary_files', '/files/binary', binary_file);
  }


  $scope.source_files = {};
  $scope.binary_files = {};

  $scope.clear_file_cache = function() {
    $scope.source_files = {};
    $scope.binary_files = {};
  }

  $scope.clear_one_file_cache = function(tc) {
    console.log(tc);
    delete $scope.source_files[tc + '.s'];
    delete $scope.binary_files[tc];

  }

  self.load_status();

  $scope.exit_status_name = function(s) {
    switch(s) {
      case 0:   return "OK";
      case 139: return "segfault";
      case 124: return "timeout";
      default:  return "unknown";
    }
  }
}
